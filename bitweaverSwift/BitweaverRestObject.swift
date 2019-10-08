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
import SwiftyJSON

@objc(BitweaverRestObject)
class BitweaverRestObject: JSONableObject {
    
    // REST Mappable properties
    @objc dynamic var contentUuid: UUID = UUID()     /* Universal Unique ID for content, created by your app */
    @objc dynamic var contentId: NSNumber?          /* Content ID created by remote system */
    @objc dynamic var userId: NSNumber?             /* User ID on the remote system that created the content */
    @objc dynamic var contentTypeGuid: String = ""   /* Title of the content */
    @objc dynamic var title: String?             /* Title of the content */
    @objc dynamic var displayUri: URL?               /* URL of the */
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

    var localHash: [String: String] = [:]

    var primaryId: String? { return contentId != nil ? contentId?.stringValue : contentUuid.uuidString }

    var isRemote: Bool { return contentId != nil }
    var isLocal: Bool { return contentId == nil }
    
    var remoteUri: String { return gBitSystem.apiBaseUri+"?content_id="+(self.contentId?.stringValue ?? self.contentUuid.uuidString) }

    var restBaseUri: String { return gBitSystem.apiBaseUri+"api/" }
    var restUri: String { return restBaseUri+"content/"+(self.contentId?.stringValue ?? self.contentUuid.uuidString) }

    var remoteUrl: URL? { return URL.init(string: remoteUri) }

    var localProjectsUrl: URL? { return BitweaverAppBase.dirForDataStorage( "local/"+contentTypeGuid ) }
    private var localPath: URL? { return localProjectsUrl?.appendingPathComponent(contentUuid.uuidString) }
	
//    var cacheProjectsUrl: URL? { return BitweaverAppBase.dirForDataStorage( "user-"+(gBitUser.userId?.stringValue ?? "0")+"/"+contentTypeGuid ) }
//    private var cachePath: URL? { return cacheProjectsUrl?.appendingPathComponent(primaryId?.description ?? "0") }
    
    var contentFile: URL? { return getFile(for: "content.json") }
    var localFile: URL? { return getFile(for: "local.json") }
    
    override func initProperties() {
        createdDate = Date()
        lastModifiedDate = Date()
    }
	
	func resetUniqueIdentifiers() {
		contentUuid = UUID()
	}
/*
    static func newObject( className: String, propertyHash: [String: Any] ) -> BitweaverRestObject? {
        if let productClass = NSClassFromString(className) as? BitweaverRestObject.Type {
            return productClass.init(fromHash: propertyHash)
        }
        return nil
    }
*/

    func getFile(for fileName: String) -> URL? {
//        if let contentDir = (gBitUser.isAuthenticated() && primaryId != nil) ? cachePath : localPath, createDirectory(contentDir) {
        if let contentDir = localPath, createDirectory(contentDir) {
            return contentDir.appendingPathComponent(fileName)
        }
        return nil
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

    override func getAllPropertyMappings() -> [String: String] {
        var mappings: [String: String] = [:]
        
        let sendableProperties = getSendablePropertyMappings()
        for (k, v) in sendableProperties {
            mappings[k] = v
        }
        
        let remoteProperties = getRemotePropertyMappings()
        for (k, v) in remoteProperties {
            mappings[k] = v
        }
        
        return mappings
    }
	
    override func getRemotePropertyMappings() -> [String: String] {
        var mappings = [
            "content_id": "contentId",
            "content_type_guid": "contentTypeGuid",
            "user_id": "userId",
            "date_created": "createdDate",
            "date_last_modified": "lastModifiedDate",
            "uuid": "contentUuid",
            "display_uri": "displayUri"
        ]

		for (k, v) in super.getAllPropertyMappings() { mappings[k] = v }
		return mappings
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
    
    func createDirectory(_ directory: URL) -> Bool {
        var ret = true
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            ret = false
            print("\(error)")
        }
        return ret
    }

    func getUploadFiles() -> [String: URL] {
        return [:]
    }

	enum UploadStatus: String {
		case Error
		case Start
		case Uploading
		case Success
	}
	
    func storeRemote(uploadFiles: Bool = true, uploadCallback: @escaping (UploadStatus, String) -> Void) {
        if !isUploading {
            startUpload()

			uploadCallback(.Start, "Starting Upload...")
            NotificationCenter.default.post(name: NSNotification.Name("ContentUploading"), object: self)

            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    if let conId = self.contentId {
                        multipartFormData.append(conId.description.data(using: .utf8)!, withName: "content_id")
                    }
                    multipartFormData.append(self.contentUuid.description.data(using: .utf8)!, withName: "uuid")
                    
                    if let jsonData = self.toJsonData() {
                        multipartFormData.append(jsonData, withName: "object_json")
                    }

                    if uploadFiles {
                        for (key, fileUrl) in self.getUploadFiles() {
                            multipartFormData.append(fileUrl, withName: key, fileName: fileUrl.lastPathComponent, mimeType: fileUrl.mimeType())
                        }
                    }
                },
                usingThreshold: UInt64.init(),
                to: restUri,
                method: .post,
                headers: gBitSystem.httpHeaders(),
                encodingCompletion: { encodingResult in
					var ret: UploadStatus = .Error
                    var errorMessage = ""
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.uploadProgress { progress in
                            self.uploadPercentage = 100.0 * progress.fractionCompleted // make sure we don't have zero
                            self.uploadMessage = "Uploading..."
                            NotificationCenter.default.post(name: NSNotification.Name("ContentUploading"), object: self)
//                            print(progress.fractionCompleted)
                        }
                        upload.responseSwiftyJSON { response in
                            if let statusCode = response.response?.statusCode {
                                self.uploadStatus = HTTPStatusCode(rawValue: statusCode) ?? HTTPStatusCode.none
                                switch statusCode {
                                case 200 ... 399:
                                    if let json = response.result.value {
                                        self.updateRemoteProperties(fromJSON: json)
                                        self.storeLocal() // let's save the current live values - perhaps content_id has changed
                                        self.dirty = false
                                    }
									ret = .Success
                                case 400 ... 499:
                                    if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                        errorMessage = utf8Text
                                    } else {
                                        errorMessage = gBitSystem.httpError( response: response, request: response.request )
                                    }
                                default:
                                    errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(statusCode), response.request?.url?.host ?? "")
                                }
                                NotificationCenter.default.post(name: NSNotification.Name("ContentUploadComplete"), object: self)
                            }
                            uploadCallback(ret, errorMessage)
                        }
                    case .failure(let encodingError):
                        self.uploadStatus = HTTPStatusCode.none
                        errorMessage = encodingError.localizedDescription
						uploadCallback(.Error, errorMessage)
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
        if let fileURL = contentFile, let jsonString = toJsonString() {
            var errorMessage = ""
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
