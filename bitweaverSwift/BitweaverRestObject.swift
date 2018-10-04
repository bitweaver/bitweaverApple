//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverRestObject.swift
//  Liberty
//
//  Created by Christian Fowler on 11/15/11.
//  Copyright 2011 Viovio.com. All rights reserved.
//

import Foundation

@objc(BitweaverRestObject)
class BitweaverRestObject: NSObject {
    // REST Mappable properties
    var contentUuid:UUID = UUID()            /* Universal Unique ID for content, created by your app */
    @objc dynamic var contentId: NSNumber?    /* Content ID created by remote system */
    @objc dynamic var userId: NSNumber?       /* User ID on the remote system that created the content */
    @objc dynamic var contentTypeGuid:String = ""           /* Title of the content */
    @objc dynamic var title:String = ""           /* Title of the content */
    @objc dynamic var displayUri:URL!      /* URL of the */
    @objc dynamic var createdDate:Date?
    @objc dynamic var lastModifiedDate:Date?
    
    var jsonHash: [String:String] = [:]

    var primaryId:NSNumber? {
        get {
            return contentId
        }
    }
    
    var isRemote:Bool { get { return primaryId != nil } }
    var isLocal:Bool { get { return primaryId == nil } }

    var pathBase:String { get {
       var pathBase = ""
        if gBitUser.isAuthenticated() {
            pathBase += "user-"+(gBitUser.userId?.stringValue ?? "0")+"/"
        } else {
            pathBase += "local/"
        }
        return pathBase+contentTypeGuid+"/"
    } }
    
    var jsonDir:URL? { get {
        return BitweaverAppBase.dirForDataStorage( pathBase )
    } }

    var jsonFile:URL? { get {
        var contentDir = pathBase
        if primaryId != nil {
            contentDir += (primaryId?.description)!
        } else {
            contentDir += contentUuid.uuidString
        }
        return BitweaverAppBase.fileForDataStorage("content.json", contentDir )
    } }
    
    func getAllPropertyMappings() -> [String : String] {
        var mappings = [
            "content_id" : "contentId",
            "content_type_guid" : "contentTypeGuid",
            "user_id" : "userId",
            "date_created" : "createdDate",
            "date_last_modified" : "lastModifiedDate",
//            "uuid" : "contentUuid",
            "display_uri" : "displayUri"
        ]
        let sendableProperties = getSendablePropertyMappings()
        for (k, v) in sendableProperties {
            mappings[k] = v
        }
        return mappings
    }

    func setField(_ propertyName:String,_ stringValue:String ) {
        if responds(to: NSSelectorFromString(propertyName)) {
            if propertyName.hasSuffix("Date") {
                setValue(stringValue.toDateISO8601(), forKey: propertyName )
            } else if propertyName.hasSuffix("Uri") {
                let nativeValue = URL.init(string: stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Id") || propertyName.hasSuffix("Count")  {
                let nativeValue = Int(stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Uuid") {
                let nativeValue = UUID.init(uuidString: stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Color") {
                let nativeValue = BWColor.init(hexString: stringValue)
                setValue(nativeValue, forKey: propertyName )
            } else if propertyName.hasSuffix("Image") {
                if let remoteUrl = URL.init(string: stringValue) {
                    let nativeValue = BWImage.init(byReferencing: remoteUrl )
                    setValue(nativeValue, forKey: propertyName )
                }
            } else {
                setValue(stringValue, forKey: propertyName )
            }
//            jsonHash[name] = value
//            storeToDisk()
        } else {
            BitweaverAppBase.log("setField failed: %@ = %@", propertyName, stringValue)
        }
    }
    
    func getField(_ name:String ) -> Any {
        return jsonHash[name] as Any
    }
    
    func getSendablePropertyMappings() -> [String : String] {
        let mappings = [
            "title" : "title"
        ]
        return mappings
    }

    class func generateUuid() -> String? {
        return UUID().uuidString
    }
    
    func createDirectory(_ directory: String) -> Bool {
        var ret = true
        
        let fileManager = FileManager.default
        
        // Create the root bookPath
        do {
            if !(fileManager.fileExists(atPath: directory )) {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            ret = false
            print("\(error)")
        }
        return ret
    }

    func load(fromJson remoteHash: [String:Any]) {
        jsonHash.removeAll()
        for (key,value) in remoteHash {
            if value is String {
                jsonHash[key] = value as? String
            } else if let valueObject = value as AnyObject? {
                jsonHash[key] = valueObject.description
            }
        }
        let properties = getAllPropertyMappings()
        for (remoteKey,remoteValue) in remoteHash {
            if let propertyName = properties[remoteKey] {
                NSLog( "loadRemote %@=>%@", remoteKey, propertyName );
                if let stringValue = remoteValue as? String {
                    setField(propertyName, stringValue)
                }
            }
        }
    }
    
    func newObject(_ className:String ) -> BitweaverRestObject? {
        var classNames:[String] = [className,self.myClassName]
        classNames.append(self.myClassName)
        
        for className in classNames {
            if let productClass = NSClassFromString(className) as? NSObject.Type {
                let productObject = productClass.init()
                if let productObject = productObject as? BitweaverRestObject {
                    return productObject
                }
            }
        }
        return nil
    }
    
    func storeToDisk() {
        var ret = false

        do {
            if let fileURL = jsonFile {
                var jsonStore = jsonHash
                for (key,propName) in getAllPropertyMappings() {
                    if let propValue = value(forKey:propName) as AnyObject? {
                        if propValue is NSNumber || propValue is String {
                            jsonStore[key] = propValue.description
                        } else if propValue is String {
                            jsonStore[key] = propValue as? String
                        }
                    }
                }
                    
                var jsonString = "{"
                for (key,value) in jsonStore {
                    jsonString += "\""+key+"\":\""+value+"\",\n"
                }
                jsonString += "}"
                
                try jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
                print( fileURL.description )
            }
            ret = true
        } catch {/* error handling here */}

//        return ret
    }

}
