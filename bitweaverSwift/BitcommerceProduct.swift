//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitcommerceProduct.swift
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

import Alamofire
import SwiftyJSON
import os.log

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

@objc(BitcommerceProduct)
class BitcommerceProduct: BitweaverRestObject {
    // REST properties
    @objc dynamic var productId: NSNumber?    /* Content ID created by remote system */
    @objc dynamic var productTypeName: String?
    @objc dynamic var remoteTypeClass: String = "BitcommerceProduct"
    @objc dynamic var productModel: String = ""
    @objc dynamic var productDefaultIcon: String = ""
    var enabled: [Bool] = []
    var images: [String: String] = [:]

    override var remoteUri: String { return gBitSystem.apiBaseUri+"bookstore/"+(productId?.description ?? contentUuid.uuidString) }

    override func initProperties() {
        super.initProperties()
        contentTypeGuid = "bitproduct"
        remoteTypeClass = getRemoteTypeClass()
    }

    func getRemoteTypeClass() -> String {
        return NSStringFromClass(type(of: self))
    }
    
    override func getRemotePropertyMappings() -> [String: String] {
        var mappings = [
            "product_id": "productId",
            "product_model": "productModel",
            "product_type_name": "productTypeName",
            "product_type_icon": "productDefaultIcon"
        ]

        for (k, v) in super.getRemotePropertyMappings() { mappings[k] = v }
        return mappings
    }

    override func getSendablePropertyMappings() -> [String: String] {
        var mappings = [
            "product_type_class": "remoteTypeClass"
        ]
        for (k, v) in super.getSendablePropertyMappings() { mappings[k] = v }
        return mappings
    }

	override func resetUniqueIdentifiers() {
		super.resetUniqueIdentifiers()
		productId = nil
	}
	
    func isValid() -> Bool {
        return productId != nil
    }

    func getEditViewController() -> BWViewController {
        return getViewController("Edit")
    }

    func getPreviewViewController() -> BWViewController {
        return getViewController("Preview")
    }

    private func getViewController(_ type: String) -> BWViewController {
        let controllerClass: String = remoteTypeClass+type+"ViewController"
        if let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as? String,
           let ret: BitcommerceProductViewController.Type = NSClassFromString( bundleName + "." + controllerClass ) as? BitcommerceProductViewController.Type {
            return ret.init()
        } else {
            return BitcommerceProductViewController.init()
        }
    }

    func getTypeImageDefault() -> BWImage {
        return BWImage.init(named: "NSMultipleDocuments") ?? BWImage.init()
    }

    func getTypeImage() -> BWImage {
        var ret: BWImage?
        if !productDefaultIcon.isEmpty {
            let imageUrl = URL.init(fileURLWithPath: productDefaultIcon)
            ret = BWImage.init(named: imageUrl.deletingPathExtension().lastPathComponent) ?? nil
        }
        return ret ?? getTypeImageDefault()
    }

    static func getProductClass( classNames: [String] ) -> BitcommerceProduct.Type? {
        for className in classNames {
            if let productClass = NSClassFromString(className) as? BitcommerceProduct.Type {
                return productClass
            }
        }
        return nil
    }
    
    static func newProduct( json: JSON ) -> BitcommerceProduct? {
        // default is type of class invoked
        var classNames: [String] = ["BitcommerceProduct"]
        let productClass = json["product_type_class"].stringValue
        if !productClass.isEmpty {
            // will attempt to create product of specific type listed
            classNames.insert(productClass, at: 0)
        }
        if let productClass = getProductClass(classNames: classNames) {
            return productClass.init(fromJSON: json)
        }
        return nil
    }
/*
    static func newProduct( propertyHash: [String: Any] ) -> BitcommerceProduct? {
        // default is type of class invoked
        var classNames: [String] = ["BitcommerceProduct"]
        if let productClass = propertyHash["product_type_class"] as? String {
            // will attempt to create product of specific type listed
            classNames.insert(productClass, at: 0)
        }
        if let productClass = getProductClass(classNames: classNames) {
            return productClass.init(fromHash: propertyHash)
        }
        return nil
    }
*/
    func getList( completion: @escaping ([String: BasePrintProduct]) -> Void ) {
//        loadLocal( completion: completion )
        loadRemote( completion: completion )
    }

    func loadLocal( completion: @escaping ([String: BasePrintProduct]) -> Void ) {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: localProjectsUrl!, includingPropertiesForKeys: resourceKeys,
                                                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!

        var productList: [String: BasePrintProduct] = [:]

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    let dirUuid = fileURL.lastPathComponent
                    let jsonUrl = fileURL.appendingPathComponent("content.json")
                    if fileManager.fileExists(atPath: jsonUrl.path) {
                        let data = try Data(contentsOf: jsonUrl, options: .mappedIfSafe)
                        let json = try JSON.init(data: data)
                        let newProduct = BasePrintProduct.init(fromJSON: json)
                        productList[dirUuid] = newProduct
                        break
                    }
                }
            } catch {
//                os_log(error)
            }
        }
        completion( productList )
        // Send a notification event user has just logged in.
        NotificationCenter.default.post(name: NSNotification.Name("ProductListLoaded"), object: self)
    }

    func loadRemote( completion: @escaping ([String: BasePrintProduct]) -> Void ) {
        if gBitUser.isAuthenticated() {
            let headers = gBitSystem.httpHeaders()
            Alamofire.request(gBitSystem.apiBaseUri+"api/products/list",
                              method: .get,
                              parameters: nil,
                              encoding: URLEncoding.default,
                              headers: headers)
                .validate()
                .responseSwiftyJSON { [weak self] response in
                    switch response.result {
                    case .success :
                        var productList = [String: BasePrintProduct]()
                        if let json = response.result.value {
                            json.forEach { (_, projectJson) in
                                if let prodType = projectJson["product_type_class"].string {
                                    let prod = BasePrintProduct.init(fromJSON: projectJson)
                                    prod.cacheLocal()
                                    productList[prod.contentUuid.uuidString] = prod
                                }
                            }
                        }
                        completion( productList )
                        // Send a notification event user has just logged in.
                        NotificationCenter.default.post(name: NSNotification.Name("ProductListLoaded"), object: self)
                    case .failure :
                        //let errorMessage = gBitSystem.httpError( response:response, request:response.request )
                        //gBitSystem.log( errorMessage )
                        completion( [:] )
                    }
            }
        }
    }
}
