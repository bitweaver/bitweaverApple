//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitcommerceProduct.swift
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

import Cocoa
import Alamofire

class BitcommerceProduct: BitweaverRestObject {
    // REST properties
    @objc dynamic var productId: NSNumber?    /* Content ID created by remote system */
    @objc dynamic var productTypeName: String?
    @objc dynamic var productTypeClass: String = ""
    @objc dynamic var productModel: String = ""
    @objc dynamic var productDefaultIcon: String = ""
    var enabled: [Bool] = []
    var images: [String:String] = [:]

    override init(){
        super.init()
        contentTypeGuid = "bitproduct"
    }
    
    convenience init(fromJson hash: [String:Any]) {
        self.init()
        load(fromJson: hash)
    }

    override func getAllPropertyMappings() -> [String : String] {
        var mappings = [
            "product_id" : "productId",
            "product_model" : "productModel",
            "product_type_name" : "productTypeName",
            "product_type_icon" : "productDefaultIcon"
        ]

        for (k, v) in super.getAllPropertyMappings() { mappings[k] = v }
        return mappings
    }

    override func load(fromJson remoteHash: [String:Any]) {
        super.load(fromJson: remoteHash)
    }
    
    override func getSendablePropertyMappings() -> [String : String] {
        var mappings = [
            "product_type_class" : "productTypeClass"
        ]
        for (k, v) in super.getSendablePropertyMappings() { mappings[k] = v }
        return mappings
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
    
    private func getViewController(_ type:String) -> BWViewController {
        let controllerClass:String = self.productTypeClass+type+"ViewController";
        print(controllerClass)
        if let ret: BWViewController.Type = NSClassFromString( Bundle.main.infoDictionary!["CFBundleName"] as! String + "." + controllerClass ) as? BWViewController.Type {
            return ret.init()
        } else {
            return BitcommerceProductViewController.init()
        }
    }
    
    func getTypeImage() -> BWImage {
        var ret = BWImage.init(named: "NSAdvanced")
        if let defaultImage = jsonHash["product_type_icon"] {
            let imageUrl = URL.init(fileURLWithPath: defaultImage)
            ret = NSImage.init(named:imageUrl.deletingPathExtension().lastPathComponent)
        }
        return ret ?? NSImage.init(named: "NSAdvanced")!
    }
    
    func jsonToProduct(fromJson jsonHash:[String:Any] ) -> BitcommerceProduct? {
        if let className = jsonHash["product_type_class"] as? String, let productObject = newObject( className ) {
            if let productObject = productObject as? BitcommerceProduct {
                productObject.load(fromJson:jsonHash)
                return productObject
            }
        }
        return nil
    }
    
    func getList( completion: @escaping (Dictionary<String, BitcommerceProduct>) -> Void ) {
        loadLocal( completion:completion )
        loadRemote( completion:completion )
    }
    
    func loadLocal( completion: @escaping (Dictionary<String, BitcommerceProduct>) -> Void ) {
        var productList:Dictionary<String, BitcommerceProduct> = [:]
        
        if jsonDir != nil {
        
            let fileManager = FileManager.default
            let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            let enumerator = FileManager.default.enumerator(at: jsonDir!, includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles,.skipsSubdirectoryDescendants], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    if resourceValues.isDirectory! {
                        let dirUuid = fileURL.lastPathComponent
                        let jsonUrl = fileURL.appendingPathComponent("content.json")
                        print( jsonUrl )
                        if fileManager.fileExists(atPath: jsonUrl.path) {
                            let data = try Data(contentsOf: jsonUrl, options: .mappedIfSafe)
                            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                            if let jsonHash = jsonResult as? Dictionary<String, String> {
                                if let newProduct = jsonToProduct(fromJson: jsonHash) {
                                    if let localUuid = UUID.init(uuidString: dirUuid) {
                                        newProduct.contentUuid = localUuid
                                    }
                                    productList[dirUuid] = newProduct
                                    print( "Loaded: " + dirUuid.description)
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
            completion( productList )
            // Send a notification event user has just logged in.
            NotificationCenter.default.post(name: NSNotification.Name("ProductListLoaded"), object: self)
        }
    }
    
    func loadRemote( completion: @escaping (Dictionary<String, BitcommerceProduct>) -> Void ) {
        if BitweaverUser.active.isAuthenticated() {
            let headers = gBitSystem.httpHeaders()
            Alamofire.request(gBitSystem.apiBaseUri+"products/list",
                              method: .get,
                              parameters: nil,
                              encoding: URLEncoding.default,
                              headers:headers)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success :
                        if let jsonList = response.result.value as? [String: [String:Any]] {
                            var productList = Dictionary<String, BitcommerceProduct>()
                            for (_,jsonHash) in jsonList as [String: [String:Any]] {
                                if let newProduct = self.jsonToProduct(fromJson: jsonHash) {
                                    newProduct.storeToDisk()
                                    productList[newProduct.contentUuid.uuidString] = newProduct
                                }
                            }
                            completion( productList )
                        }
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
