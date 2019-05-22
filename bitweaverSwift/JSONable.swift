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

protocol JSONable {
    func toJsonData() -> Data?
    func toJsonString() -> String?
    func getAllPropertyMappings() -> [String: String]
}

class JSONableObject: NSObject, JSONable {
    
    override init() {
        super.init()
        initProperties()
    }
    
    required init(fromJSON json: JSON) {
        super.init()
        initProperties()
        self.load(fromJSON: json)
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
/*
    required init(fromHash propertyHash: [String: Any]) {
        super.init()
        initProperties()
        self.load(fromHash: propertyHash)
    }
    
    func load(fromHash propertyHash: [String: Any]) {
        var remoteHash: [String: Any] = [:]
        for (key, value) in propertyHash {
            if value is String {
                remoteHash[key] = value as? String
            } else if value is NSNull {
                remoteHash[key] = ""
            } else if let hash = value as? [String: Any] {
                remoteHash[key] = loadBranch(key: key, hash: hash)
            } else if let valueObject = value as AnyObject? {
                remoteHash[key] = valueObject.description
            }
        }
        let properties = getAllPropertyMappings()
        for (remoteKey, remoteValue) in remoteHash {
            if let propertyName = properties[remoteKey] {
                //                NSLog( "load field %@=>%@", remoteKey, propertyName );
                setProperty(propertyName, remoteValue)
            }
        }
    }
    
    func loadBranch( key: String, hash: [String: Any] ) -> [String: Any] {
        var ret: [String: Any] = [:]
        return ret
    }
*/
    /// Base implementation, intended to be overridden by all subclasses.
    ///
    /// - Returns: empty Dictionary
    func getAllPropertyMappings() -> [String: String] {
        return [:]
    }
    
    // users object property
    func setProperty(_ propertyName: String, _ jsonValue: JSON ) {
        setProperty(propertyName, jsonValue.stringValue)
    }
    
    func setProperty(_ propertyName: String, _ propertyValue: Any ) {
        if let stringValue = propertyValue as? String, responds(to: NSSelectorFromString(propertyName)) {
            if #available(OSX 10.12, *) {
                //                os_log( "%@ = %@", propertyName, stringValue )
            }
            if propertyName.hasSuffix("Date") {
                setValue(stringValue.toDateISO8601(), forKey: propertyName )
            } else if propertyName.hasSuffix("Uri") {
                let nativeValue = URL.init(string: stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Id") || propertyName.hasSuffix("Count") {
                let nativeValue = Int(stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Point") {
                let nativeValue = NSPointFromString(stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Rect") {
                let nativeValue = NSRectFromString(stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Size") {
                let nativeValue = NSSizeFromString(stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Uuid") {
                let nativeValue = UUID.init(uuidString: stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Color") {
                let nativeValue = BWColor.init(hexString: stringValue)
                //                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Image") {
                if let remoteUrl = URL.init(string: stringValue) {
                    let nativeValue = BWImage.init(byReferencing: remoteUrl )
                    setValue(nativeValue, forKey: propertyName )
                }
            } else {
                setValue(stringValue, forKey: propertyName )
            }
        } else {
            BitweaverAppBase.log("set property failed: %@ = %@", propertyName, propertyValue)
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
        var jsonValue: Any
        
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
        } else if isNumeric(propValue) {
            jsonValue = propValue
        } else {
            jsonValue = stringFromAny( propValue )
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
    
    private func toJsonBranch( propertyHash: [String: Any]) -> [String: Any] {
        var jsonHash: [String: Any] = [:]
        
        for (key, value) in propertyHash {
            if let subHash = value as? [String: Any] {
                // Recurse down in for nested objects
                jsonHash[key] = toJsonBranch(propertyHash: subHash)
            } else if let subArray = value as? [Any] {
                // Recurse down in for nested objects
                jsonHash[key] = toJsonBranch(propertyArray: subArray)
            } else {
                jsonHash[key] = jsonValue(value)
            }
        }
        
        return jsonHash
    }
    
    func toJsonHash() -> [String: Any] {
        var jsonHash: [String: Any] = [:]
        for (key, propertyName) in getAllPropertyMappings() {
            if let propValue = value(forKey: propertyName) as Any? {
                if let subHash = propValue as? [String: Any] {
                    // Recurse down in for nested objects
                    jsonHash[key] = toJsonBranch(propertyHash: subHash)
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
}
