//
//  BitweaverAppBase.swift
//  Bitweaver API Demo
//
//  Copyright (c) 2012 Bitweaver.org. All rights reserved.
//

// Forward declare BitweaverUser as it requires AppDelegate
//
//  BitweaverAppBase.swift
//  Bitweaver API Demo
//
//  Copyright (c) 2012 Bitweaver.org. All rights reserved.
//

import Foundation
import Alamofire

class BitweaverAppBase: NSObject {
    var authLogin: String = ""
    var authPassword: String = ""
    
    var apiBaseUri: String = ""
    var apiKey: String = ""
    var apiSecret: String = ""

    override init() {
        super.init()
        apiBaseUri = Bundle.main.object(forInfoDictionaryKey: "BW_API_URI") as! String
        apiKey = Bundle.main.object(forInfoDictionaryKey: "BW_API_KEY") as! String
        apiSecret = Bundle.main.object(forInfoDictionaryKey: "BW_API_SECRET") as! String
    }
    
    func httpHeaders() -> [String:String] {
        var headers:[String:String] = [:]
        if authLogin.count > 0 && authPassword.count > 0 {
            let credentialData = "\(authLogin):\(authPassword)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            headers["Authorization"] = "Basic \(base64Credentials)"
        }
        
        headers["API"] = "API consumer_key="+apiKey
        
        return headers
    }
    
    func httpError(response: DataResponse<Any>, request: URLRequest) -> String? {
        if let error = response.error as? AFError {
            switch error {
            case .invalidURL(let url):
                print("Invalid URL: \(url) - \(error.localizedDescription)")
            case .parameterEncodingFailed(let reason):
                print("Parameter encoding failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
            case .multipartEncodingFailed(let reason):
                print("Multipart encoding failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
            case .responseValidationFailed(let reason):
                print("Response validation failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
                
                switch reason {
                case .dataFileNil, .dataFileReadFailed:
                    print("Downloaded file could not be read")
                case .missingContentType(let acceptableContentTypes):
                    print("Content Type Missing: \(acceptableContentTypes)")
                case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                    print("Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)")
                case .unacceptableStatusCode(let code):
                    print("Response status code was unacceptable: \(code)")
                }
            case .responseSerializationFailed(let reason):
                print("Response serialization failed: \(error.localizedDescription)")
                print("Failure Reason: \(reason)")
            }
            
            print("Underlying error: \(error.underlyingError)")
        } else if let error = response.error as? URLError {
            print("URLError occurred: \(error)")
        } else {
            print("Unknown error: \(response.error)")
        }
        
        var errorMessage = ""
        if let statusCode = response.response?.statusCode {
            if response.response?.statusCode == 408 {
                errorMessage += "Request timed out. Please check your internet connection."
            } else {
                errorMessage += "Unknown error."
            }
            
            if let anURL = request.url {
                return String(format: "%@(ERR %ld %@)", errorMessage, statusCode, anURL as CVarArg)
            }
        }
        return nil

    }
}

protocol BitweaverApp {
    func showAuthenticationDialog()
    func authenticationSuccess()
    func authenticationFailure(with request: URLRequest?, response: HTTPURLResponse?, error: Error?, json: Any?)
    func registrationFailure(_ failureMessage: String?)
}
