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
import Cocoa
import Alamofire

// App wide alias for iOS and macOS cross platform convenience
typealias BWImage = NSImage
typealias BWViewController = NSViewController

// Step 2: You might want to add these APIs that UIImage has but NSImage doesn't.
extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        
        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }
    //    convenience init?(named name: String) {
    //        self.init(named: Name(name))
    //    }
}



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
    
    func httpError(response: DataResponse<Any>, request: URLRequest?) -> String? {
        var logMessage = ""
        if let error = response.error as? AFError {
            switch error {
            case .invalidURL(let url):
                logMessage += "Invalid URL: \(url) - \(error.localizedDescription)\n"
            case .parameterEncodingFailed(let reason):
                logMessage += "Parameter encoding failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            case .multipartEncodingFailed(let reason):
                logMessage += "Multipart encoding failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            case .responseValidationFailed(let reason):
                logMessage += "Response validation failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
                
                switch reason {
                case .dataFileNil, .dataFileReadFailed:
                    logMessage += "\nDownloaded file could not be read"
                case .missingContentType(let acceptableContentTypes):
                    logMessage += "\nContent Type Missing: \(acceptableContentTypes)"
                case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                    logMessage += "\nResponse content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                case .unacceptableStatusCode(let code):
                    logMessage += "\nResponse status code was unacceptable: \(code)"
                }
            case .responseSerializationFailed(let reason):
                logMessage += "Response serialization failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            }
            
            if (error.underlyingError != nil) {
                logMessage += "\nUnderlying error: "//\(error.underlyingError)"
            }
        } else if let error = response.error as? URLError {
            logMessage += "\nURLError occurred: \(error)"
        } else {
            logMessage += "\nUnknown error: "//\(response.error)"
        }

        //OSLog("This is info that may be helpful during development or debugging.", log: .default, type: .error)
        
        var errorMessage = ""
        if let statusCode = response.response?.statusCode {
            if response.response?.statusCode == 408 {
                errorMessage += "Request timed out. Please check your internet connection."
            } else {
                errorMessage += "Unknown error."
            }
            
            if let anURL = request?.url {
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
