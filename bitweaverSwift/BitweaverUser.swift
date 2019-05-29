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
import SwiftyJSON

let gBitUser = BitweaverUser.active

protocol BitweaverUserDelegate: class {
    func userDidLoginSuccess()
    func userDidLoginFailure()
}

class BitweaverUser: BitweaverRestObject {
    @objc dynamic var email: String?
    @objc dynamic var login: String?
    @objc dynamic var realName: String?
    @objc dynamic var lastLogin: String?
    @objc dynamic var registrationDate: Date?
    @objc dynamic var portraitPath = ""
    @objc dynamic var portraitUrl: URL?
    @objc dynamic var avatarPath = ""
    @objc dynamic var avatarUrl: URL?
    @objc dynamic var logoPath = ""
    @objc dynamic var logoUrl: URL?
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""

    weak var userDelegtate: BitweaverUserDelegate?
    
    var displayName: String {
        var ret = ""
        if isAuthenticated() {
            if let name = realName, !name.isEmpty {
                ret = name
            } else if let name = login, !name.isEmpty {
                ret = name
            } else if let name = email, !name.isEmpty {
                ret = name
            }
        }
        return ret
    }

    var callbackSelectorName = ""
    var callbackObject: AnyObject?

    var products: [String: BitcommerceProduct] = [:]

    // Prevent multiple
    static let active = BitweaverUser()

    override var primaryId: String? { return userId?.stringValue }

    override func initProperties() {
        contentTypeGuid = "bituser"
    }
    
    override func getRemotePropertyMappings() -> [String: String] {
        var mappings = [
            "user_id": "userId",
            "login": "login",
            "last_login": "lastLogin",
            "registration_date": "registrationDate"
/*
            "portrait_path" : "portraitPath",
            "portrait_url" : "portraitUrl",
            "avatar_path" : "avatarPath",
            "avatar_url" : "avatarUrl",
            "logo_path" : "logoPath",
            "logo_url" : "logoUrl"
 */
        ]
        for (k, v) in super.getRemotePropertyMappings() { mappings[k] = v }
        return mappings
    }

    override func getSendablePropertyMappings() -> [String: String] {
        var mappings = [
            "email": "email",
            "real_name": "realName"
        ]
        for (k, v) in super.getSendablePropertyMappings() { mappings[k] = v }
        return mappings
    }

    func isAuthenticated() -> Bool {
        return userId != nil
    }

    /*
    func verifyAuthentication() -> Bool {
        if !isAuthenticated() {
            gBitSystem.showAuthenticationDialog()
        }
        return isAuthenticated()
    }
    */

    func register(_ authLogin: String, _ authPassword: String, handler: BitweaverLoginViewController) {

        // Assume login was email field, update here for registration
        email = authLogin

        var parameters: [String: String] = [:]
        let properties = getSendablePropertyMappings()
        for (key, name) in properties {
            parameters[key] = value(forKey: name) as? String
        }
        parameters["email"] = authLogin
        parameters["password"] = authPassword
        parameters["real_name"] = NSFullUserName()

        let headers = gBitSystem.httpHeaders()

        Alamofire.request(gBitSystem.apiBaseUri+"users",
                method: .post,
                parameters: parameters,
                encoding: URLEncoding.default,
                headers: headers)
            .validate(statusCode: 200..<500)
            .responseSwiftyJSON { [weak self] response in

                var ret = false
                var errorMessage: String = ""

                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case 200 ... 399:
                        ret = true
                        self?.authenticate(authLogin: authLogin, authPassword: authPassword, handler: handler)
                    case 400 ... 499:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                            print("Data: \(utf8Text)")
                        }

                        errorMessage = "Registration failed. \n"+gBitSystem.httpError( response: response, request: response.request )
                    default:
                        errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                    }
                }
                handler.authenticationResponse(success: ret, message: errorMessage )
        }
    }

    func authenticate( authLogin: String, authPassword: String, handler: BitweaverLoginViewController ) {

        var headers = gBitSystem.httpHeaders()
        let credentialData = "\(authLogin):\(authPassword)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        headers["Authorization"] = "Basic \(base64Credentials)"

        Alamofire.request(gBitSystem.apiBaseUri+"api/users/authenticate",
                          method: .get,
                          parameters: nil,
                          encoding: URLEncoding.default,
                          headers: headers)
            .validate(statusCode: 200..<500)
            .responseJSON { [weak self] response in

                var ret = false
                var errorMessage: String = ""

                if let statusCode = response.response?.statusCode {
                    switch statusCode {
                    case 200 ... 399:

                        // cache login credentials
                        gBitSystem.authLogin = authLogin
                        gBitSystem.authPassword = authPassword

                        // Set all cookies so subsequent requests pass on info
                        var cookies: [HTTPCookie] = []
                        if let aFields = response.response?.allHeaderFields as? [String: String], let anUri = URL(string: gBitSystem.apiBaseUri ) {
                            cookies = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
                        }

                        if cookies.count > 0 {
                            for cookie in cookies {
                                HTTPCookieStorage.shared.setCookie(cookie)
                            }
                        }

                        if response.response?.mimeType == "application/json" {
                            let userJSON = JSON(response.result.value as Any)
                            self?.load(fromJSON: userJSON)
                            // Send a notification event user has just logged in.
                            NotificationCenter.default.post(name: NSNotification.Name("UserAuthenticated"), object: self)
                        }
                        ret = true

                    case 400 ... 499:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                            print("Data: \(utf8Text)")
                        }

                        // errorMessage = gBitSystem.httpError( response:response, request:response.request! )!
                        errorMessage = String(format: "Invalid login and password. Perhaps you need to register?\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                        //gBitSystem.authenticationFailure(with: request, response: response, error: response.error, json: response.result.value)
                    default:
                        errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                    }
                    handler.authenticationResponse(success: ret, message: errorMessage )
                }
        }
    }

    func logout( completion: @escaping () -> Void ) {
        gBitSystem.authLogin = ""
        gBitSystem.authPassword = ""
        let properties = getAllPropertyMappings()
        for (key, _) in properties {
            if let varName = properties[key] {
                if responds(to: NSSelectorFromString(varName)) {
                    if varName == "contentUuid" {
                        setValue(UUID(), forKey: varName )
                    } else {
                        setValue(nil, forKey: varName )
                    }
                }
            }
        }

        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        completion()
        NotificationCenter.default.post(name: NSNotification.Name("UserUnloaded"), object: self)
    }

    override func load(fromJSON json: JSON) {
        super.load(fromJSON: json)
        NotificationCenter.default.post(name: NSNotification.Name("UserLoaded"), object: self)
    }
}
