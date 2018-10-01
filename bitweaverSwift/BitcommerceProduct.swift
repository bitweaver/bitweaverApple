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
    @objc dynamic var productTypeName: String = ""
    @objc dynamic var productTypeClass: String = ""
    @objc dynamic var productModel: String = ""
    @objc dynamic var productDefaultIcon: String = ""
    var enabled: [Bool] = []
    var images: [String:String] = [:]

    convenience init(fromHash hash: [String:Any]) {
        self.init()
        load(fromRemoteProperties: hash)
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

    override func load(fromRemoteProperties remoteHash: [String:Any]) {
        super.load(fromRemoteProperties: remoteHash)
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

    func getViewController() -> BWViewController {
        let controllerClass:String = self.productTypeClass+"ViewController";
        print(controllerClass)
        if let ret: BWViewController.Type = NSClassFromString( Bundle.main.infoDictionary!["CFBundleName"] as! String + "." + controllerClass ) as? BWViewController.Type {
            return ret.init()
        } else {
            return BitcommerceProductViewController.init()
        }
    }
    
    func getTypeImage() -> BWImage {
        var ret = BWImage.init(named: "NSAdvanced")
        if let defaultImage = objectHash["product_type_icon"] as? String {
            let imageUrl = URL.init(fileURLWithPath: defaultImage)
            ret = NSImage.init(named:imageUrl.deletingPathExtension().lastPathComponent)
        }
        return ret ?? NSImage.init(named: "NSAdvanced")!
    }
    
    func jsonToProducts(withHash jsonList: [String: [String:Any]] ) -> Dictionary<String, BitcommerceProduct> {
        var productList = Dictionary<String, BitcommerceProduct>()
        for (productId,hash) in jsonList as [String: [String:Any]] {
            var classNames:[String] = []
            if hash["product_type_class"] != nil {
                classNames.append( hash["product_type_class"] as! String )
            }
            classNames.append(self.myClassName)

            for className in classNames {
                if let productClass = NSClassFromString(className) as? NSObject.Type {
                    let productObject = productClass.init()
                    if productObject is BitcommerceProduct {
                        productList[productId] = productObject as? BitcommerceProduct
                        productList[productId]?.load(fromRemoteProperties:hash)
                        break
                    }
                }
            }
        }
        return productList
    }
    
    func getList( completion: @escaping (Dictionary<String, BitcommerceProduct>) -> Void ) {
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
                        let productList = self.jsonToProducts(withHash: jsonList)
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
