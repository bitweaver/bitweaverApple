//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitcommerceProduct.swift
//  PBPro API Demo
//
//  Created by Christian Fowler on 6/27/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

class BitcommerceProduct: BitweaverRestObject {
    // REST properties
    var productId: Int?
    var productType = ""
    var enabled: [Bool] = []
    var images: [String:String] = [:]

    convenience init(fromHash hash: [String : Any]?) {
        self.init()
        load(fromRemoteProperties: hash)
    }

    override func getAllPropertyMappings() -> [String : String]? {
        var mappings = [
            "product_id" : "productId"
        ]

        for (k, v) in super.getAllPropertyMappings()! { mappings[k] = v }
        return mappings
    }

    override func getSendablePropertyMappings() -> [String : String]? {
        var mappings = [
            "product_type" : "productType"
        ]
        for (k, v) in super.getSendablePropertyMappings()! { mappings[k] = v }
        return mappings
    }

    func isValid() -> Bool {
        return productId != nil
    }
}
