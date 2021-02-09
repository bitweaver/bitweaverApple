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
import WebKit
import Alamofire
import SwiftyJSON
#if os(iOS)
import UIKit
#else
import Cocoa
#endif

class BitweaverAppBase: NSObject {
    
    enum LogLevel: String {
        case Error
        case Warning
    }
    
    var authLogin: String = ""
    var authPassword: String = ""

    var apiBaseUri: String = ""
    var apiKey: String = ""
    var apiSecret: String = ""

    override init() {
        super.init()
        apiBaseUri = Bundle.main.object(forInfoDictionaryKey: "BW_API_URI") as? String ?? ""
        apiKey = Bundle.main.object(forInfoDictionaryKey: "BW_API_KEY") as? String ?? ""
        apiSecret = Bundle.main.object(forInfoDictionaryKey: "BW_API_SECRET") as? String ?? ""
    }

    //return os major version 13,14,15
    var osVersion: String {
        return osMajorVersion.description+"."+osMinorVersion.description+"."+osPatchVersion.description
    }
    
    var osMajorVersion: Int {
        return ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
    
    var osMinorVersion: Int {
        return ProcessInfo.processInfo.operatingSystemVersion.minorVersion
    }
    
    var osPatchVersion: Int {
        return ProcessInfo.processInfo.operatingSystemVersion.patchVersion
    }
    
    var buildVersion: String {
        return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "Unknown"
    }
    
    var appVersion: String {
        return  (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"
    }
    
    var hardwareModel: String {
        var ret = "Unknown"
        #if os(iOS)
        let device = UIDevice.current
        ret = device.model
        #else
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        ret = String(cString: machine)
        #endif
        
        return ret
    }
    
    var isOnWifi: Bool {
        return NetworkReachabilityManager()!.isReachableOnEthernetOrWiFi
    }
    
    var hasNetworkConnection: Bool {
        return NetworkReachabilityManager()!.isReachable
    }

    var appSupportHash: [String: String] {
        return [
            "app_version": appVersion,
            "build_version": buildVersion,
            "hardware_model": hardwareModel,
            "os_version": osVersion,
            "memory": String( (Int(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024) ).description ) + " GB"
        ]
    }
    
    static var deviceUsername: String {
        #if os(iOS)
        var device = "iPhone"
        if UIDevice.current.userInterfaceIdiom == .pad {
            device = "iPad"
        }
        var name = UIDevice.current.name.replacingOccurrences(of: device, with: "")
        name = name.replacingOccurrences(of: "’s ", with: "")
        return name
        #else
        return NSFullUserName()
        #endif
    }
    
    func httpHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        if authLogin.count > 0 && authPassword.count > 0 {
            let credentialData = "\(authLogin):\(authPassword)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            headers["Authorization"] = "Basic \(base64Credentials)"
        }

        headers["API"] = "API consumer_key="+apiKey

        return headers
    }

    static func logMessage(_ message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, columnNumber: Int = #column) {
        
        print("🤡 \(message) \n## \(fileName) - \(functionName) at line \(lineNumber)[\(columnNumber)]")
    }
    
    func httpError(response: DataResponse<JSON>, request: URLRequest?) -> String {
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

            if error.underlyingError != nil {
                logMessage += "\nUnderlying error: "//\(error.underlyingError)"
            }
        } else if let error = response.error as? URLError {
            errorMessage += "\nURLError occurred: \(error)"
        } else {
            if let messages = response.result.value {
                for (_, message) in messages {
                    errorMessage += message.stringValue+"\n"
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

    static func fileForDataStorage(_ fileName: String, _ subDirectory: String? ) -> URL? {
        if let appFolder = dirForDataStorage(subDirectory) {
            return appFolder.appendingPathComponent(fileName)
        }
        return nil
    }

    static func dirForDataStorage(_ subDirectory: String? ) -> URL? {
        let fileManager = FileManager.default
        guard let orgFolder = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        var ret: URL = orgFolder
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

	static func getCacheDir( subPath: String) -> URL? {
		return BitweaverAppBase.dirForDataStorage( "cache/"+subPath )
	}
	
    static func log(level: LogLevel, _ format: String, _ args: Any...) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = fmt.string(from: Date())

        let pinfo = ProcessInfo()
        let pname = pinfo.processName
        let pid = pinfo.processIdentifier
        var tid = UInt64(0)
        pthread_threadid_np(nil, &tid)

        var stringArgs: [CVarArg] = []
        for arg in args {
            stringArgs.append(String(describing: arg))
        }

        let logString = level.rawValue + " \(timestamp) \(pname)[\(pid):\(tid)] " + String(format: format, arguments: stringArgs)
        print(logString)
    }
}

protocol BitweaverApp {
    func showAuthenticationDialog()
}
