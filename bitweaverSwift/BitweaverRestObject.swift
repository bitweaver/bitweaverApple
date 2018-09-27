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
    @objc dynamic var uuId:String = ""            /* Universal Unique ID for content, created by your app */
    @objc dynamic var contentId: NSNumber?    /* Content ID created by remote system */
    @objc dynamic var userId: NSNumber?       /* User ID on the remote system that created the content */
    @objc dynamic var title:String = ""           /* Title of the content */
    @objc dynamic var displayUri:URL!      /* URL of the */
    @objc dynamic var createdDate = Date()
    @objc dynamic var lastModifiedDate = Date()
    
    var productHash: [String:Any] = [:]
    
    override init() {
        super.init()
    }
    
    func getAllPropertyMappings() -> [String : String]? {
        var mappings = [
            "content_id" : "contentId",
            "user_id" : "userId",
            "date_created" : "createdDate",
            "date_last_modified" : "lastModifiedDate",
            "uuid" : "uuId",
            "display_uri" : "displayUri"
        ]
        if let sendableProperties = getSendablePropertyMappings() {
            for (k, v) in sendableProperties {
                mappings[k] = v
            }
        }
        return mappings
    }

    func getField(_ name:String ) -> Any {
        return productHash[name] as Any
    }
    
    func getSendablePropertyMappings() -> [String : String]? {
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
    
    func load(fromRemoteProperties remoteHash: [String:Any]) {
        productHash = remoteHash
        if let properties = getAllPropertyMappings() {
            for (remoteKey,remoteValue) in remoteHash {
                if let propertyName = properties[remoteKey] {
                    do {
                        if let remoteValueString = remoteValue as? String {
                            NSLog( "loadRemote %@=>%@ = %@", remoteKey, propertyName, remoteValueString );
                            if propertyName.hasSuffix("Date") {
                                let RFC3339DateFormatter = DateFormatter()
                                RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                                RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                                let remoteValueDate = RFC3339DateFormatter.date(from: remoteValueString)
                            
                                setValue(remoteValueDate, forKey: propertyName )
                            } else if propertyName.hasSuffix("Uri") {
                                let nativeValue = URL.init(string: remoteValueString)
                                setValue(nativeValue, forKey: propertyName )
                            } else if propertyName.hasSuffix("Id") || propertyName.hasSuffix("Count")  {
                                let nativeValue = Int(remoteValueString)
                                setValue(nativeValue, forKey: propertyName )
                            } else if propertyName.hasSuffix("Color") {
                                let nativeValue = BWColor.init(hexString: remoteValueString)
                                setValue(nativeValue, forKey: propertyName )
                            } else if propertyName.hasSuffix("Image") {
                                if let remoteUrl = URL.init(string: remoteValueString) {
                                    let nativeValue = BWImage.init(byReferencing: remoteUrl )
                                    setValue(nativeValue, forKey: propertyName )
                                }
                            } else if remoteValue is Array<Any> {
                                print( "have dictAtrin" )
                            } else {
                                setValue(remoteValueString, forKey: propertyName )
                            }
                        }
                    } catch {
                        gBitSystem.log("loadRemote failed: %@ = %@ => %@", remoteKey, remoteValue, propertyName)
                    }
                }
            }
        }
    }
}
