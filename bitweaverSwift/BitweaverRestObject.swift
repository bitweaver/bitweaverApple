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

@objc(BitweaverRestObject)
class BitweaverRestObject: NSObject {
    // REST Mappable properties
    @objc dynamic var contentUuid:UUID = UUID()     /* Universal Unique ID for content, created by your app */
    @objc dynamic var contentId: NSNumber?          /* Content ID created by remote system */
    @objc dynamic var userId: NSNumber?             /* User ID on the remote system that created the content */
    @objc dynamic var contentTypeGuid:String = ""   /* Title of the content */
    @objc dynamic var title:String = ""             /* Title of the content */
    @objc dynamic var displayUri:URL!               /* URL of the */
    @objc dynamic var createdDate:Date?
    @objc dynamic var lastModifiedDate:Date?

    var isUploading = false
    var uploadPercentage: Float = 0.0
    var uploadMessage = ""

    var jsonHash: [String:String] = [:]

    var primaryId:String? {
        get {
            return contentId != nil ? contentId?.stringValue : contentUuid.uuidString
        }
    }
    
    func remoteUrl() -> String {
        return gBitSystem.apiBaseUri+"content/"+(self.contentId?.stringValue ?? self.contentUuid.uuidString);
    }
    func startUpload() {
        uploadPercentage = 0.01
        isUploading = true
        NotificationCenter.default.post(name: NSNotification.Name("UploadingStart"), object: self)
    }
    
    func cancelUpload() {
        uploadPercentage = 0.0
        isUploading = false
        NotificationCenter.default.post(name: NSNotification.Name("UploadingCancel"), object: self)
    }
    

    var isRemote:Bool { get { return primaryId != nil } }
    var isLocal:Bool { get { return primaryId == nil } }

    var localPathBase:String { get {
       var pathBase = ""
        if gBitUser.isAuthenticated() {
            pathBase += "user-"+(gBitUser.userId?.stringValue ?? "0")+"/"
        } else {
            pathBase += "local/"
        }
        return pathBase+contentTypeGuid+"/"
    } }
    
    var localUrl:URL? { get {
        return BitweaverAppBase.dirForDataStorage( localPathBase )
    } }

    var jsonFile:URL? { get {
        var contentDir = localPathBase
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
            "uuid" : "contentUuid",
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
//            storeLocal()
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
                    productObject.createdDate = Date()
                    productObject.lastModifiedDate = Date()
                    return productObject
                }
            }
        }
        return nil
    }

    func exportToHash() -> [String:String] {
        var jsonStore = jsonHash
        for (key,propName) in getAllPropertyMappings() {
            if let propValue = value(forKey:propName) as AnyObject? {
                if let nativeValue = propValue as? UUID {
                    jsonStore[key] = nativeValue.uuidString
                } else if let nativeValue = propValue as? URL {
                    jsonStore[key] = nativeValue.absoluteString
                } else if let nativeValue = propValue as? Date {
                    jsonStore[key] = nativeValue.toStringISO8601()
                } else if let nativeValue = propValue as? BWColor {
                    jsonStore[key] = nativeValue.toHexString()
                } else if let nativeValue = propValue as? NSNumber {
                    if nativeValue.floatValue != 0 {
                        jsonStore[key] = nativeValue.description
                    }
                } else if let nativeValue = propValue as? String {
                    if nativeValue.count > 0 {
                        jsonStore[key] = nativeValue
                    }
                } else {
                    print( "unknown storeLocal: ", propName )
                }
            }
        }
        return jsonStore
    }

    func exportToJson() -> String {
        let jsonStore = self.exportToHash()
        var jsonString = "{"
        for (key,value) in jsonStore {
            jsonString += "\""+key+"\":\""+value+"\",\n"
        }
        jsonString += "}"
        
        return jsonString
    }
    
    func store(completion: @escaping (BitweaverRestObject,Bool,String) -> Void) {
        if isRemote {
            storeRemote(completion: completion)
        } else {
            storeLocal()
        }
    }
    
    private func storeRemote(completion: @escaping (BitweaverRestObject,Bool,String) -> Void) {
        if !isUploading {
            startUpload()
            
            NotificationCenter.default.post(name: NSNotification.Name("ProductUploading"), object: self)
            
            let exportHash = exportToHash()
            let headers = gBitSystem.httpHeaders()
            
            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    for (key,value) in exportHash {
                        multipartFormData.append(value.data(using: .utf8)!, withName: key)
                    }
//                  if let imageData = frontCoverImage?.toDataJPG() {
//                      multipartFormData.appendBodyPart(data: imageData, name: "front_cover", fileName: "front_cover_upload.jpg", mimeType: "image/jpeg")
//                  }
//                  multipartFormData.append(unicornImageURL, withName: "unicorn")
//                  multipartFormData.append(rainbowImageURL, withName: "rainbow")
                },
                usingThreshold:UInt64.init(),
                to:remoteUrl(),
                method:.put,
                headers:headers,
                encodingCompletion: { encodingResult in
                    var ret = false
                    var errorMessage = ""
                    switch encodingResult {
                        case .success(let upload, _, _):
                            upload.responseJSON { response in
                                if let statusCode = response.response?.statusCode {
                                    switch statusCode {
                                    case 200 ... 399:
                                        if let jsonHash = response.result.value as? [String:Any] {
                                            self.load(fromJson: jsonHash)
                                            ret = true
                                        } else {
                                            errorMessage = "JSON Format Error"
                                        }
                                    case 400 ... 499:
                                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                            print("Data: \(utf8Text)")
                                        }
                                        
                                        errorMessage = gBitSystem.httpError( response:response, request:response.request )
                                    default:
                                        errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                                    }
                                }
                                completion(self,ret,errorMessage)
                            }
                        case .failure(let encodingError):
                            errorMessage = encodingError.localizedDescription
                            completion(self,ret,errorMessage)
                    }
                }
            )
            
            /* SWIFTCONVERT
             var putRequest: NSMutableURLRequest? = gBitweaverHTTPClient.multipartFormRequest(withMethod: "POST", path: restUrlPath, parameters: parameters, constructingBodyWith: { formData in
             if( frontCover != nil ) {
             [formData appendPartWithFileData:UIImageJPEGRepresentation(frontCover, 0.85) name:@"front_cover_file" fileName:@"ratio11-cover-front" mimeType:@"image/jpeg"];
             }
             
             if( backCover != nil ) {
             [formData appendPartWithFileData:UIImageJPEGRepresentation(backCover, 0.85) name:@"back_cover_file" fileName:@"back-cover" mimeType:@"image/jpeg"];
             }
             
             let data = NSData(contentsOfFile: Bundle.main.path(forResource: "\(self.ratio)-text-block", ofType: "pdf") ?? "") as Data?
             formData?.appendPart(withFileData: data, name: "pdf_text", fileName: "\(self.ratio)-text-block.pdf", mimeType: "application/pdf")
             })
             
             gBitweaverHTTPClient.prepareRequestHeaders(putRequest)
             
             restOperation = AFJSONRequestOperation(request: putRequest! as URLRequest,
             success: { request, response, JSON in
             self.load(fromRemoteProperties: JSON as! [String : String])
             self.uploadPercentage = 100.0
             self.uploadMessage = "Upload complete!"
             NotificationCenter.default.post(name: NSNotification.Name("ProductUploading"), object: self)
             }, failure: { request, response, error, JSON in
             let errorMessage = gBitweaverHTTPClient.errorMessage(withResponse: response!, urlRequest: request, json: JSON as! [String:Any] )
             self.uploadMessage = "Upload failed: "+errorMessage!
             self.uploadPercentage = 100.0
             NotificationCenter.default.post(name: NSNotification.Name("ProductUploading"), object: self)
             })
             
             restOperation?.setUploadProgressBlock = { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
             self.uploadPercentage = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) + 0.01 // make sure we don't have zero
             self.uploadMessage = "Uploading..."
             NotificationCenter.default.post(name: NSNotification.Name("ProductUploading"), object: self)
             }
             
             uploadMessage = "Preparing upload."
             NotificationCenter.default.post(name: NSNotification.Name("ProductUploading"), object: self)
             if let anOperation = restOperation {
             OperationQueue().addOperation(anOperation)
             }
             */
        }
    }
    
    // access method to save local copy of remote object
    func cacheLocal() {
        storeLocal()
    }
    
    private func storeLocal() {
        if let fileURL = jsonFile {
            let jsonString = exportToJson()
            do {
                try jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
                print( fileURL.description )
            } catch {
                /* error handling here */
                print("Failed do save JSON to ", fileURL)
            }
        }
    }

}
