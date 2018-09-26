//  Converted to Swift 4 by Swiftify v4.1.6809 - https://objectivec2swift.com/
//
//  BitweaverUser.swift
//  Bitweaver API Demo
//
//  Created by Christian Fowler on 2/4/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

//
//  BitweaverUser.swift
//  AQGridView
//
//  Created by Christian Fowler on 1/28/12.
//  Copyright (c) 2012 Viovio.com. All rights reserved.
//

import Foundation
import Alamofire

let gBitUser = BitweaverUser.shared

class BitweaverUser: BitweaverRestObject {
    @objc dynamic var email = ""
    @objc dynamic var login = ""
    @objc dynamic var realName = ""
    @objc dynamic var lastLogin = ""
    @objc dynamic var currentLogin = ""
    @objc dynamic var registrationDate = ""
    @objc dynamic var challenge = ""
    @objc dynamic var passDue = ""
    @objc dynamic var user = ""
    @objc dynamic var valid = ""
    @objc dynamic var isRegistered = ""
    @objc dynamic var portraitPath = ""
    @objc dynamic var portraitUrl = ""
    @objc dynamic var avatarPath = ""
    @objc dynamic var avatarUrl = ""
    @objc dynamic var logoPath = ""
    @objc dynamic var logoUrl = ""
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""

    var callbackSelectorName = ""
    var callbackObject: AnyObject?
    
    var products = Dictionary<String, BitcommerceProduct>()

    static let shared = BitweaverUser()
    
    // Prevent multiple
    override private init(){
        super.init()
    }
    
    
    override func getAllPropertyMappings() -> [String:String]? {
        var mappings = [
            "last_login" : "lastLogin",
            "current_login" : "currentLogin",
            "registration_date" : "registrationDate",
            "is_registered" : "isRegistered",
            "portrait_path" : "portraitPath",
            "portrait_url" : "portraitUrl",
            "avatar_path" : "avatarPath",
            "avatar_url" : "avatarUrl",
            "logo_path" : "logoPath",
            "logo_url" : "logoUrl"
        ]
        for (k, v) in super.getAllPropertyMappings()! { mappings[k] = v }
        return mappings
    }

    override func getSendablePropertyMappings() -> [String:String]? {
        var mappings = [
            "email" : "email",
            "login" : "login",
            "real_name" : "realName",
            "user" : "user"
        ]
        for (k, v) in super.getSendablePropertyMappings()! { mappings[k] = v }
        return mappings
    }

    func isAuthenticated() -> Bool {
        return userId != nil
    }

    func verifyAuthentication(_ object: BitcommerceProduct?, selectorName: String?, callbackParameter: Any?) -> Bool {
        if !isAuthenticated() {
            callbackObject = object
            callbackSelectorName = selectorName ?? ""
            gBitSystem.showAuthenticationDialog()
        } else {
//clang diagnostic push
//clang diagnostic ignored "-Warc-performSelector-leaks"
// SWIFTCONVERT            (object as AnyObject).perform(NSSelectorFromString(selectorName!))
//clang diagnostic pop
        }
        return isAuthenticated()
    }

    func register(_ authLogin:String, withPassword authPassword:String, handler:BitweaverLoginViewController) {
        //var ret: Bool = false
        //var errorMessage: String = ""

        // Assume login was email field, update here for registration
        self.email = authLogin

        var parameters: [String:String] = [:]
        if let properties = getSendablePropertyMappings() {
            for (key,name) in properties {
                parameters[key] = self.value(forKey:name) as? String
            }
            parameters["password"] = authPassword
        }
/* SWIFTCONVERT
        let putRequest: NSMutableURLRequest? = gBitweaverHTTPClient.multipartFormRequest(withMethod: "POST", path: "users", parameters: parameters, constructingBodyWith: { formData in })

        gBitweaverHTTPClient.prepareRequestHeaders(putRequest)

        if let operation = AFJSONRequestOperation(request: putRequest! as URLRequest, success: { request, response, JSON in
                ret = true
            self.load(fromRemoteProperties: JSON as! [String : String])
                handler.registrationResponse(success: ret, message: errorMessage, response: response! )
            }, failure: { request, response, error, JSON in
                errorMessage = gBitweaverHTTPClient.errorMessage(withResponse: response!, urlRequest: request, json: (JSON as? [String : Any])!)!
                handler.registrationResponse(success: ret, message: errorMessage, response: response! )
        }) {
            OperationQueue().addOperation(operation)
        }
 */
    }

    func authenticate( authLogin:String, authPassword:String, handler:BitweaverLoginViewController ) {
        var ret: Bool = false
        var errorMessage: String = ""
        
        
        let credentialData = "\(authLogin):\(authPassword)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        var headers = gBitSystem.httpHeaders()
        headers["Authorization"] = "Basic \(base64Credentials)"
        
        Alamofire.request(gBitSystem.apiBaseUri+"users/authenticate",
                          method: .get,
                          parameters: nil,
                          encoding: URLEncoding.default,
                          headers:headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                    case .success :
                        ret = true
                        
                        // cache login credentials
                        gBitSystem.authLogin = authLogin
                        gBitSystem.authPassword = authPassword
                        
                        // Set all cookies so subsequent requests pass on info
                        var cookies: [HTTPCookie] = []
                        if let aFields = response.response?.allHeaderFields as? [String : String], let anUri = URL(string: gBitSystem.apiBaseUri ) {
                            cookies = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
                        }
                        
                        if cookies.count > 0 {
                            for cookie in cookies {
                                HTTPCookieStorage.shared.setCookie(cookie)
                            }
                        }

                        if let properties = response.result.value as? [String: Any] {
                            self.load(fromRemoteProperties:properties)
                            gBitSystem.authenticationSuccess()
                            // Send a notification event user has just logged in.
                            NotificationCenter.default.post(name: NSNotification.Name("UserAuthenticated"), object: self)
                        }
                        
                        handler.authenticationResponse(success: ret, message: errorMessage )
                    case .failure :
                        // errorMessage = gBitSystem.httpError( response:response, request:response.request! )!
                        errorMessage = String(format: "Invalid login and password. Perhaps you need to register?\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                        //gBitSystem.authenticationFailure(with: request, response: response, error: response.error, json: response.result.value)
                        handler.authenticationResponse(success: ret, message: errorMessage )
                    }
                }
/* SWIFTCONVERT
        if let operation = AFJSONRequestOperation(request: gBitweaverHTTPClient.request(withPath: "users/authenticate") as URLRequest?, success: { request, response, JSON in
                ret = true
                // Set all cookies so subsequent requests pass on info
                var cookies: [HTTPCookie] = []
                if let aFields = response?.allHeaderFields as? [String : String], let anUri = URL(string: gBitweaverHTTPClient.apiBaseUri ) {
                    cookies = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
                }

                if cookies.count > 0 {
                    for cookie in cookies {
                        HTTPCookieStorage.shared.setCookie(cookie)
                    }
                }

                self.load(fromRemoteProperties: JSON as! [String : Any])
                APPDELEGATE.authenticationSuccess()

                // Send a notification event user has just logged in.
                NotificationCenter.default.post(name: NSNotification.Name("UserAuthenticated"), object: self)

                handler.authenticationResponse(success: ret, message: errorMessage, response: response! )

            }, failure: { request, response, error, JSON in
                APPDELEGATE.authenticationFailure(with: request, response: response, error: error, json: JSON)
                errorMessage = gBitweaverHTTPClient.errorMessage(withResponse: response!, urlRequest: request, json: JSON as! [String : Any])!
                if( errorMessage.count == 0 ) {
                    errorMessage = String(format: "Invalid login and password. Perhaps you need to register?\n(EC %ld %@)", Int(response?.statusCode ?? 0), request?.url?.host ?? "")
                    }
                handler.authenticationResponse(success: ret, message: errorMessage, response: response! )
        }) {
            OperationQueue().addOperation(operation)
        }
 */
    }

    func logout() {
        gBitSystem.authLogin = ""
        gBitSystem.authPassword = ""
        if let properties = getAllPropertyMappings() {
            for (key,_) in properties {
                if let varName = properties[key] {
                    if responds(to: NSSelectorFromString(varName)) {
                        setValue(nil, forKey: varName )
                    }
                }
            }
        }
        let cookieStorage = HTTPCookieStorage.shared
        for each: HTTPCookie? in cookieStorage.cookies ?? [] {
            if let anEach = each {
                cookieStorage.deleteCookie(anEach)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("UserUnloaded"), object: self)
    }

    override func load(fromRemoteProperties remoteHash: [String : Any]) {
        super.load(fromRemoteProperties: remoteHash)
        NotificationCenter.default.post(name: NSNotification.Name("UserLoaded"), object: self)
    }
}
