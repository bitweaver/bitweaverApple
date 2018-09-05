//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverHTTPClient.swift
//  designer
//
//  Created by Christian Fowler on 4/9/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

class BitweaverHTTPClient: AFHTTPClient {
    class func shared() -> BitweaverHTTPClient? {
        var _sharedClient: BitweaverHTTPClient? = nil
        var onceToken: Int = 0

        if (onceToken == 0) {
            _sharedClient = super.initWithBaseURL(URL(string: APPDELEGATE?.apiBaseUri)) as? BitweaverHTTPClient
            assert(_sharedClient != nil, "Shared REST client not initialized")
        }
        onceToken = 1

        _sharedClient?.setAuthorizationHeaderWithUsername(APPDELEGATE.authLogin, password: APPDELEGATE?.authPassword)
        return _sharedClient
    }

    class func request(withPath urlPath: String?) -> NSMutableURLRequest? {

        var request: NSMutableURLRequest? = BitweaverHTTPClient.shared()?.request(withMethod: "GET", path: urlPath, parameters: nil)
        BitweaverHTTPClient.prepareRequestHeaders(request)

        return request
    }

    class func prepareRequestHeaders(_ request: NSMutableURLRequest?) {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "APP_API_KEY") as? String {
            request?.setValue("API consumer_key=\""+apiKey+"\"", forHTTPHeaderField: "API")
        }
    }

    class func errorMessage(withResponse response: HTTPURLResponse, urlRequest request: URLRequest?, json JSON: [AnyHashable : Any]?) -> String? {

        var errorMessage = ""
        for key: String? in (JSON?.keys)! {
            if let aKey = JSON?[key] {
                errorMessage += "\(aKey)\n"
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
            return String(format: "%@(ERR %ld %@)", errorMessage, response.statusCode, anURL)
        }
        return nil
    }
}
