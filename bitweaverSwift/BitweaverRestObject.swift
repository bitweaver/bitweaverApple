//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverRestObject.swift
//  Liberty
//
//  Created by Christian Fowler on 11/15/11.
//  Copyright 2011 Viovio.com. All rights reserved.
//

import Foundation
import Alamofire
import os.log

@objc(BitweaverRestObject)
class BitweaverRestObject: NSObject {
    // REST Mappable properties
    @objc dynamic var contentUuid: UUID = UUID()     /* Universal Unique ID for content, created by your app */
    @objc dynamic var contentId: NSNumber?          /* Content ID created by remote system */
    @objc dynamic var userId: NSNumber?             /* User ID on the remote system that created the content */
    @objc dynamic var contentTypeGuid: String = ""   /* Title of the content */
    @objc dynamic var title: String?             /* Title of the content */
    @objc dynamic var displayUri: URL!               /* URL of the */
    @objc dynamic var createdDate: Date?
    @objc dynamic var lastModifiedDate: Date?

    var displayTitle: String { return title ?? defaultTitle }
    var defaultTitle: String { return "Untitled "+defaultName }
    var defaultName: String { return contentTypeGuid }

    var dirty: Bool = false // Has local modifications
    var uploadStatus: HTTPStatusCode = HTTPStatusCode.none
    var uploadPercentage: Double = 0.0
    var uploadMessage = ""

    var isUploading: Bool { return uploadStatus.rawValue > HTTPStatusCode.none.rawValue && uploadStatus.rawValue < HTTPStatusCode.ok.rawValue }

    var remoteHash: [String: String] = [:]
    var localHash: [String: String] = [:]

    var primaryId: String? { return contentId != nil ? contentId?.stringValue : contentUuid.uuidString }

    override init() {
        super.init()
        initProperties()
    }

    func initProperties() {
    }

    func remoteUrl() -> String {
        return gBitSystem.apiBaseUri+"content/"+(self.contentId?.stringValue ?? self.contentUuid.uuidString)
    }

    func startUpload() {
        uploadPercentage = 0.01
        uploadStatus = HTTPStatusCode.continue
        NotificationCenter.default.post(name: NSNotification.Name("UploadingStart"), object: self)
    }

    func cancelUpload() {
        uploadPercentage = 0.0
        uploadStatus = HTTPStatusCode.clientClosedRequest
        NotificationCenter.default.post(name: NSNotification.Name("UploadingCancel"), object: self)
    }

    var isRemote: Bool { return contentId != nil }
    var isLocal: Bool { return contentId == nil }

    var localProjectsUrl: URL? {
        return BitweaverAppBase.dirForDataStorage( "local/"+contentTypeGuid )
    }

    var localPath: URL? {
        return localProjectsUrl?.appendingPathComponent(contentUuid.uuidString)
    }

    var cacheProjectsUrl: URL? {
        return BitweaverAppBase.dirForDataStorage( "user-"+(gBitUser.userId?.stringValue ?? "0")+"/"+contentTypeGuid )
    }

    private var cachePath: URL? {
        return cacheProjectsUrl?.appendingPathComponent(primaryId?.description ?? "0")
    }

    var contentFile: URL? {
        let contentDir = (gBitUser.isAuthenticated() && primaryId != nil) ? cachePath : localPath
        return contentDir?.appendingPathComponent("content.json")
    }

    var localFile: URL? {
        let contentDir = (gBitUser.isAuthenticated() && primaryId != nil) ? cachePath : localPath
        return contentDir?.appendingPathComponent("local.json")
    }

    func getAllPropertyMappings() -> [String: String] {
        var mappings = [
            "content_id": "contentId",
            "content_type_guid": "contentTypeGuid",
            "user_id": "userId",
            "date_created": "createdDate",
            "date_last_modified": "lastModifiedDate",
            "uuid": "contentUuid",
            "display_uri": "displayUri"
        ]
        let sendableProperties = getSendablePropertyMappings()
        for (k, v) in sendableProperties {
            mappings[k] = v
        }
        return mappings
    }

    // users object property
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
        } else {
            BitweaverAppBase.log("set property failed: %@ = %@", propertyName, propertyValue)
        }
    }

    func getField(_ name: String ) -> Any {
        return remoteHash[name] as Any
    }

    func getSendablePropertyMappings() -> [String: String] {
        let mappings = [
            "title": "title"
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

    func load(fromJson: [String: Any]) {
        remoteHash.removeAll()
        for (key, value) in fromJson {
            if value is String {
                remoteHash[key] = value as? String
            } else if value is NSNull {
                remoteHash[key] = "" //valueObject.description
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

    static func newObject(_ className: String, _ remoteHash: [String: Any] ) -> BitweaverRestObject? {
        if let productClass = NSClassFromString(className) as? NSObject.Type {
            let productObject = productClass.init()
            if let productObject = productObject as? BitweaverRestObject {
                productObject.createdDate = Date()
                productObject.lastModifiedDate = Date()
                productObject.load(fromJson: remoteHash)
                return productObject
            }
        }
        return nil
    }

    func getProperty(_ propertyName: String ) -> String? {
        var ret: String?
        if let propValue = value(forKey: propertyName) as AnyObject? {
            if let nativeValue = propValue as? UUID {
                ret = nativeValue.uuidString
            } else if let nativeValue = propValue as? URL {
                ret = nativeValue.absoluteString
            } else if let nativeValue = propValue as? Date {
                ret = nativeValue.toStringISO8601()!
            } else if let nativeValue = propValue as? BWColor {
                ret = nativeValue.toHexString()
            } else if let nativeValue = propValue as? NSNumber {
                if nativeValue.floatValue != 0 {
                    ret = nativeValue.description
                }
            } else if let nativeValue = propValue as? String {
                if nativeValue.count > 0 {
                    ret = nativeValue
                }
            } else {
                print( "unknown storeLocal: ", propertyName )
            }
        }
        return ret
    }

    func localToHash() -> [String: String] {
        var remoteStore = remoteHash
        for (key, propertyName) in getAllPropertyMappings() {
            if let propString = getProperty(propertyName) {
                remoteStore[key] = propString
            }
        }
        return remoteStore
    }

    func toJson() -> String {
        let jsonStore = self.remoteToHash()
        var jsonString = "{"
        for (key, value) in jsonStore {
            jsonString += "\""+key+"\":\""+value+"\",\n"
        }
        jsonString += "}"

        return jsonString
    }

    func remoteToHash() -> [String: String] {
        var remoteStore = remoteHash
        for (key, propertyName) in getAllPropertyMappings() {
            if let propString = getProperty(propertyName) {
                remoteStore[key] = propString
            }
        }
        return remoteStore
    }

    func completeStoreRemote( newProduct: BitweaverRestObject, isSuccess: Bool, message: String ) {
        do {
            if isSuccess {
                if let cacheUrl = self.cachePath, let localUrl = self.localPath, FileManager.default.fileExists(atPath: localUrl.path) {
                    if FileManager.default.fileExists(atPath: cacheUrl.path) {
                        try FileManager.default.trashItem(at: localUrl, resultingItemURL: nil)
                    } else {
                        try FileManager.default.createDirectory(at: cacheUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                        try FileManager.default.moveItem(at: localUrl, to: self.cachePath!)
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name("ProductEditRequest"), object: newProduct)
            } else {
            }
        } catch {
            BitweaverAppBase.log( "Local to Remote directory move failed: \(error)", self.localPath ?? "", self.cachePath ?? "" )
        }
    }

    func localToRemote(completion: @escaping (BitweaverRestObject, Bool, String) -> Void) {
        if isLocal {
            let completionBlock: (BitweaverRestObject, Bool, String) -> Void  = { newProduct, isSuccess, message in
                self.completeStoreRemote( newProduct: newProduct, isSuccess: isSuccess, message: message )
                completion( newProduct, isSuccess, message )
            }
            storeRemote(completion: completionBlock)
        }
    }

    func store(completion: @escaping (BitweaverRestObject, Bool, String) -> Void) {
        if isRemote {
            storeRemote(completion: completion)
        } else {
            storeLocal(completion: completion)
        }
    }

    func getUploadFiles() -> [String: URL] {
        return [:]
    }

    func storeRemote(uploadFiles: Bool = true, completion: @escaping (BitweaverRestObject, Bool, String) -> Void) {
        if !isUploading {
            startUpload()

            NotificationCenter.default.post(name: NSNotification.Name("ContentUploading"), object: self)

            let headers = gBitSystem.httpHeaders()

            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    let exportHash = self.remoteToHash()
                    for (key, value) in exportHash {
                        multipartFormData.append(value.data(using: .utf8)!, withName: key)
                    }
                    if uploadFiles {
                        for (key, fileUrl) in self.getUploadFiles() {
                            multipartFormData.append(fileUrl, withName: key, fileName: fileUrl.lastPathComponent, mimeType: fileUrl.mimeType())
                        }
                    }
//                  multipartFormData.append(unicornImageURL, withName: "unicorn")
//                  multipartFormData.append(rainbowImageURL, withName: "rainbow")
                },
                usingThreshold: UInt64.init(),
                to: remoteUrl(),
                method: .post,
                headers: headers,
                encodingCompletion: { encodingResult in
                    var ret = false
                    var errorMessage = ""
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.uploadProgress { progress in
                            self.uploadPercentage = 100.0 * progress.fractionCompleted // make sure we don't have zero
                            self.uploadMessage = "Uploading..."
                            NotificationCenter.default.post(name: NSNotification.Name("ContentUploading"), object: self)
                            print(progress.fractionCompleted)
                        }
                        upload.responseJSON { response in
                            if let statusCode = response.response?.statusCode {
                                self.uploadStatus = HTTPStatusCode(rawValue: statusCode) ?? HTTPStatusCode.none
                                switch statusCode {
                                case 200 ... 399:
                                    if let remoteHash = response.result.value as? [String: Any] {
                                        self.load(fromJson: remoteHash)
                                        self.storeLocal() // let's save the current live values - perhaps content_id has changed
                                        self.dirty = false
                                    }
                                    NotificationCenter.default.post(name: NSNotification.Name("ContentUploadComplete"), object: self)
                                    ret = true
                                case 400 ... 499:
                                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                        errorMessage = utf8Text
                                    } else {
                                        errorMessage = gBitSystem.httpError( response: response, request: response.request )
                                    }
                                default:
                                    errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(statusCode), response.request?.url?.host ?? "")
                                }
                            }
                            completion(self, ret, errorMessage)
                        }
                    case .failure(let encodingError):
                        self.uploadStatus = HTTPStatusCode.none
                        errorMessage = encodingError.localizedDescription
                        completion(self, ret, errorMessage)
                    }
                }
            )
        }
    }

    // access method to save local copy of remote object
    func cacheLocal() {
        storeLocal()
    }

    func storeLocal(completion: ((BitweaverRestObject, Bool, String) -> Void)? = nil ) {
        if let fileURL = contentFile {
            var errorMessage = ""
            let jsonString = toJson()
            do {
                try jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
                completion?(self, true, errorMessage)

                print( fileURL.description )
            } catch {
                /* error handling here */
                errorMessage = "Failed to save JSON to "+fileURL.absoluteString
                completion?(self, false, errorMessage)
            }
        }
        if let fileURL = localFile {
            var errorMessage = ""
            let jsonString = toJson()
            do {
                try jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
                completion?(self, true, errorMessage)

                print( fileURL.description )
            } catch {
                /* error handling here */
                errorMessage = "Failed to save JSON to "+fileURL.absoluteString
                completion?(self, false, errorMessage)
            }
        }
    }

}
