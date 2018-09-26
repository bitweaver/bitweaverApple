//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverHTTPClient.swift
//  designer
//
//  Created by Christian Fowler on 4/9/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

let gBitweaverHTTPClient = BitweaverHTTPClient.shared

class BitweaverHTTPClient: AFHTTPClient {
    var apiBaseUri: String = ""
    
    static let shared = BitweaverHTTPClient()

    override private init() {
        apiBaseUri = Bundle.main.object(forInfoDictionaryKey: "BW_API_URI") as! String
        super.init(baseURL:URL(string: apiBaseUri))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func request( withPath: String?) -> NSMutableURLRequest? {
        setAuthorizationHeaderWithUsername(APPDELEGATE.authLogin, password: APPDELEGATE.authPassword)

        let request = super.request(withMethod: "GET", path: withPath, parameters: nil)
        prepareRequestHeaders(request)

        return request
    }

    func prepareRequestHeaders(_ request: NSMutableURLRequest?) {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "BW_API_KEY") as? String {
            request?.setValue("API consumer_key=\""+apiKey+"\"", forHTTPHeaderField: "API")
        }
    }

    func errorMessage(withResponse response: HTTPURLResponse, urlRequest request: URLRequest?, json JSON: [String : Any]) -> String? {

        var errorMessage = ""
        if( JSON.count > 0 ) {
            for key: String in (JSON.keys) {
                if let aKey = JSON[key] {
                    errorMessage += "\(aKey)\n"
                }
            }
        }

        if errorMessage.count == 0 {
            if response.statusCode == 408 {
                errorMessage += "Request timed out. Please check your internet connection."
            } else {
                errorMessage += "Unknown error."
            }
        }

        if let anURL = request?.url {
            return String(format: "%@(ERR %ld %@)", errorMessage, response.statusCode, anURL as CVarArg)
        }
        return nil
    }
}

