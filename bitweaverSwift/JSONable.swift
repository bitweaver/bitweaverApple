//
//  JSONable.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 5/20/19.
//  Copyright © 2019 PrestoPhoto. All rights reserved.
//

import Foundation
import os.log
import SwiftyJSON
import Cocoa

protocol JSONable {
    func toJsonData() -> Data?
    func toJsonString() -> String?
    func getAllPropertyMappings() -> [String: String]
}

class JSONableObject: NSObject, JSONable {

	@objc dynamic private var objectPrefs: [String: Any] = [:]	

    override init() {
        super.init()
        initProperties()
    }
    
    required init(fromJSON json: JSON) {
        super.init()
        initProperties()
        self.load(fromJSON: json)
    }
    
    static func newObject( className: String, json: JSON ) -> BitweaverRestObject? {
        if let productClass = NSClassFromString(className) as? BitweaverRestObject.Type {
            return productClass.init(fromJSON: json)
        }
        return nil
    }
    
    func initProperties() {
    }
    
    func load(fromJSON json: JSON) {
        let properties = getAllPropertyMappings()
        for (jsonName, varName) in properties {
            if json[jsonName].exists() {
                setProperty(varName, json[jsonName])
            }
        }
    }

    func updateRemoteProperties(fromJSON json: JSON) {
        let properties = getRemotePropertyMappings()
        for (jsonName, varName) in properties {
            if json[jsonName].exists() {
                setProperty(varName, json[jsonName])
            }
        }
    }
    
    /// Base implementation, intended to be overridden by all subclasses.
    ///
    /// - Returns: empty Dictionary
    func getRemotePropertyMappings() -> [String: String] {
		return [:]
    }
    
    /// Base implementation, intended to be overridden by all subclasses.
    ///
    /// - Returns: empty Dictionary
    func getAllPropertyMappings() -> [String: String] {
		return ["preferences": "objectPrefs"]
    }
    
	func getNativeValue(propertyName: String, propertyValue: String) -> Any? {
		var ret: Any?
		
		// os_log( "%@ = %@", propertyName, stringValue )
		if propertyName.hasSuffix("Date") {
			ret = propertyValue.toDateISO8601()
		} else if propertyName.hasSuffix("Uri") {
			ret = URL.init(string: propertyValue)
		} else if propertyName.hasSuffix("Id") || propertyName.hasSuffix("Count") {
			ret = Int(propertyValue)
		} else if propertyName.hasSuffix("Point") {
			ret = NSPointFromString(propertyValue)
		} else if propertyName.hasSuffix("Rect") {
			ret = NSRectFromString(propertyValue)
		} else if propertyName.hasSuffix("Font") {
			ret = NSFont.init(cssValue: propertyValue)
		} else if propertyName.hasSuffix("Size") {
			ret = NSSizeFromString(propertyValue)
		} else if propertyName.hasSuffix("Uuid") {
			ret = UUID.init(uuidString: propertyValue)
		} else if propertyName.hasSuffix("Color") {
			ret = BWColor.init(hexValue: propertyValue)
		} else if propertyName.hasSuffix("Image") {
			if let remoteUrl = URL.init(string: propertyValue) {
				ret = BWImage.init(byReferencing: remoteUrl )
			}
		} else if propertyName.hasPrefix("is") {
			ret = (propertyValue == "true" || propertyValue == "1") ? true : false
		} else {
			ret = propertyValue
		}

		return ret
	}
	
	// users object property
	func setProperty(_ propertyName: String, _ jsonValue: JSON ) {
		if propertyName == "objectPrefs" {
			for (dictKey, dictJson) in jsonValue.dictionaryValue {
				// Create a key that isCamelCased to match auto-typing prefix/suffix in getNativeValue
				var typedKey = dictKey
				if let range = dictKey.range(of: "_") {
					typedKey = dictKey.replacingCharacters(in: range, with: " ").capitalized
				}
				setPreference(key: dictKey, value: getNativeValue(propertyName: typedKey, propertyValue: dictJson.stringValue) ?? nil)
			}
		} else {
			setProperty(propertyName, jsonValue.stringValue)
		}
	}
	
    private func setProperty(_ propertyName: String, _ propertyValue: Any ) {
        do {
            try ObjC.catchException {
				if let stringValue = propertyValue as? String, self.responds(to: NSSelectorFromString(propertyName)) {
					if let nativeValue = self.getNativeValue(propertyName: propertyName, propertyValue: stringValue) {
						self.setValue(nativeValue, forKey: propertyName )
					}
                } else {
                    BitweaverAppBase.log("set property failed: %@ = %@", propertyName, propertyValue)
                }
            }
        } catch {
			print("setProperty("+propertyName+") error ocurred: \(error)")
        }
    }
    
    func getField(_ name: String ) -> Any {
        return value(forKey: name) as Any
    }
    
    /* There are five basic value types supported by JSON Schema:
     string.
     number.
     integer.
     boolean.
     null.
     */
    private func jsonValue(_ propValue: Any ) -> Any {
        var jsonValue: Any = ""
        do {
            try ObjC.catchException {
                if let jsonObject = propValue as? JSONableObject {
                    jsonValue = jsonObject.toJsonHash()
                } else if let nativeValue = propValue as? UUID {
                    jsonValue = nativeValue.uuidString
                } else if let nativeValue = propValue as? URL {
                    jsonValue = nativeValue.absoluteString
                } else if let nativeValue = propValue as? Date {
                    jsonValue = nativeValue.toStringISO8601()!
                } else if let nativeValue = propValue as? BWColor {
                    jsonValue = nativeValue.toHexString()
                } else if let nativeValue = propValue as? NSNumber, nativeValue.floatValue != 0 {
                    jsonValue = nativeValue.description
                } else if let nativeValue = propValue as? String {
                    jsonValue = nativeValue
				} else if let nativeValue = propValue as? NSFont {
					jsonValue = nativeValue.toCssString()
                } else if self.isNumeric(propValue) {
                    jsonValue = propValue
                } else {
                    jsonValue = self.stringFromAny( propValue )
                }
            }
        } catch {
			let propValueDescription = String(format: "%@", [propValue])
			print("jsonValue("+propValueDescription+") error ocurred: \(error) ")
        }

        return jsonValue
    }
    
    func stringFromAny(_ value: Any?) -> String {
        if let nonNil = value, !(nonNil is NSNull) {
            return String(describing: nonNil)
        }
        return ""
    }
    
    func isNumeric(_ value: Any) -> Bool {
        let numericTypes: [Any.Type] = [Int.self, Int8.self, Int16.self, Int32.self, Int64.self, UInt.self, UInt8.self, UInt16.self, UInt32.self, UInt64.self, Double.self, Float.self, Float32.self, Float64.self, Decimal.self, NSNumber.self, NSDecimalNumber.self]
        return numericTypes.contains { $0 == Mirror(reflecting: value).subjectType }
    }
    
    private func toJsonBranch( propertyArray: [Any]) -> [Any] {
        var jsonArray: [Any] = []
        
        for (value) in propertyArray {
            if let subHash = value as? [String: Any] {
                // Recurse down in for nested objects
                jsonArray.append( toJsonBranch(propertyHash: subHash) )
            } else if let subArray = value as? [Any] {
                // Recurse down in for nested objects
                jsonArray.append( toJsonBranch(propertyArray: subArray) )
            } else {
                jsonArray.append( jsonValue(value) )
            }
        }
        
        return jsonArray
    }
    
    private func toJsonBranch( propertyHash: [AnyHashable: Any]) -> [String: Any] {
        var jsonHash: [String: Any] = [:]
        
        for (key, value) in propertyHash {
            if let subHash = value as? [String: Any] {
                // Recurse down in for nested objects
                jsonHash[key.description] = toJsonBranch(propertyHash: subHash)
            } else if let subArray = value as? [Any] {
                // Recurse down in for nested objects
                jsonHash[key.description] = toJsonBranch(propertyArray: subArray)
            } else {
                jsonHash[key.description] = jsonValue(value)
            }
        }
        
        return jsonHash
    }
    
    func toJsonHash() -> [String: Any] {
        var jsonHash: [String: Any] = [:]
        for (key, propertyName) in getAllPropertyMappings() {
            if let propValue = value(forKey: propertyName) as Any? {
                if let subHash = propValue as? [AnyHashable: Any] {
                    // Recurse down in for nested objects
					if subHash.count > 0 {
                    	jsonHash[key] = toJsonBranch(propertyHash: subHash)
					}
                } else if let subArray = propValue as? [Any] {
                    // Recurse down in for nested objects
                    jsonHash[key] = toJsonBranch(propertyArray: subArray)
                } else {
                    jsonHash[key] = jsonValue(propValue)
                }
            }
        }
        return jsonHash
    }
    
    func toJsonData() -> Data? {
        let jsonHash = toJsonHash()
        do {
            return try JSONSerialization.data(withJSONObject: jsonHash, options: [])
        } catch {
            print( error.localizedDescription )
        }
        
        return nil
    }
    
    func toJsonString() -> String? {
        if let jsonData = toJsonData() {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }

	func setPreference(key: String, value: Any?) {
		if value == nil {
			objectPrefs.removeValue(forKey: key)
		} else {
			objectPrefs[key] = value
		}
	}
	
	func getPreference(_ key: String, defaultValue: Any? = nil) -> Any? {
		var ret: Any? = defaultValue
		
		if objectPrefs.index(forKey: key) != nil {
			ret = objectPrefs[key]
		}
		return ret
	}
	
}
