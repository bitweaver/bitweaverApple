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
import WebKit
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
    
    func httpError(response: DataResponse<Any>, request: URLRequest?) -> String {
        var errorMessage = ""
        var logMessage = ""
        if let error = response.error as? AFError {
            switch error {
            case .invalidURL(let url):
                errorMessage += "Invalid URL: \(url) - \(error.localizedDescription)\n"
            case .parameterEncodingFailed(let reason):
                errorMessage += "Parameter encoding failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            case .multipartEncodingFailed(let reason):
                errorMessage += "Multipart encoding failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            case .responseValidationFailed(let reason):
                errorMessage += "Response validation failed: \(error.localizedDescription)"
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
                errorMessage += "Response serialization failed: \(error.localizedDescription)"
                logMessage += "\nFailure Reason: \(reason)"
            }
            
            if (error.underlyingError != nil) {
                logMessage += "\nUnderlying error: "//\(error.underlyingError)"
            }
        } else if let error = response.error as? URLError {
            errorMessage += "\nURLError occurred: \(error)"
        } else {
            if let messages = response.result.value as? [String:String] {
                for (_,message) in messages {
                    errorMessage += message+"\n"
                }
            } else if let statusCode = response.response?.statusCode {
                if response.response?.statusCode == 408 {
                    errorMessage += "Request timed out. Please check your internet connection."
                }
                
                if let anURL = request?.url {
                    return String(format: "\n%@(ERR %ld %@)", errorMessage, statusCode, anURL as CVarArg)
                }
            } else {
                errorMessage += "Unknown error: "//\(response.error)"
            }
        }

        //OSLog("This is info that may be helpful during development or debugging.", log: .default, type: .error)
        
        return errorMessage
    }
    
    static func fileForDataStorage(_ fileName:String,_ subDirectory:String? ) -> URL? {
        if let appFolder = dirForDataStorage(subDirectory) {
            return appFolder.appendingPathComponent(fileName)
        }
        return nil
    }
    
    static func dirForDataStorage(_ subDirectory:String? ) -> URL? {
        let fileManager = FileManager.default
        guard let orgFolder = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        var ret:URL = orgFolder
        if subDirectory != nil {
            ret = orgFolder.appendingPathComponent(subDirectory!)
        }
        var isDirectory: ObjCBool = false
        let folderExists = fileManager.fileExists(atPath: ret.path, isDirectory: &isDirectory)
        if !folderExists || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(at: ret, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return ret
    }
    
    static func log(_ format: String,_ args: Any...) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = fmt.string(from: Date())
        
        let pinfo = ProcessInfo()
        let pname = pinfo.processName
        let pid = pinfo.processIdentifier
        var tid = UInt64(0)
        pthread_threadid_np(nil, &tid)
        
        var stringArgs:[CVarArg] = [];
        for arg in args {
            stringArgs.append(String(describing: arg))
        }
        
        let logString = "\(timestamp) \(pname)[\(pid):\(tid)] " + String(format: format, arguments: stringArgs)
        print(logString)
    }
}

protocol BitweaverApp {
    func showAuthenticationDialog()
}


class BitweaverWebViewController: BWViewController, WKUIDelegate, WKNavigationDelegate {
    
    var webView: WKWebView  = WKWebView()
    
    var defaultUrl: URL?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        super.loadView()
        webView.frame = self.view.bounds
        webView.autoresizingMask = [.width, .height]
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.view.addSubview( webView )
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    func loadUrl( url: URL ) {
        var urlRequest = URLRequest(url: url)
        if #available(OSX 10.13, *) {
        } else {
            let cookies = HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies ?? [])
            
            var headers = urlRequest.allHTTPHeaderFields ?? [:]
            headers.merge( cookies, uniquingKeysWith: { (current, _) in current } )
            
            urlRequest.allHTTPHeaderFields = headers
        }
        
        webView.loadHTMLString("<html><body><p>Loading page...</p></body></html>", baseURL: nil)
        webView.load(urlRequest)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            //            guard let urlPath =  navigationAction.request.url?.pathComponents else { decisionHandler(.allow); return }
            //            if (urlPath.count) > 1 && urlPath[1] == "help" {
            guard let targetHost = navigationAction.request.url?.host else { decisionHandler(.allow); return }
            if targetHost != PrestoDefaults.uriHost && targetHost != "support.photobooks.pro" {
                if NSWorkspace.shared.open( navigationAction.request.url! ) {
                    decisionHandler(.cancel)
                } else {
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
