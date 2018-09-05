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

    func verifyAuthentication(_ object: PdfPhotoBookProduct?, selectorName: String?, callbackParameter: Any?) -> Bool {
        if !isAuthenticated() {
            callbackObject = object
            callbackSelectorName = selectorName ?? ""
            APPDELEGATE.showAuthenticationDialog()
        } else {
//clang diagnostic push
//clang diagnostic ignored "-Warc-performSelector-leaks"
            (object as AnyObject).perform(NSSelectorFromString(selectorName!))
//clang diagnostic pop
        }
        return isAuthenticated()
    }

    func register(_ authLogin: String, withPassword authPassword: String) {

        // Assume login was email field, update here for registration
        self.email = authLogin

        var parameters: [String:String] = [:]
        if let properties = getSendablePropertyMappings() {
            for (key,name) in properties {
                parameters[key] = self.value(forKey:name) as! String    
            }
            parameters["password"] = authPassword
        }
        var putRequest: NSMutableURLRequest? = BitweaverHTTPClient.shared()?.multipartFormRequest(withMethod: "POST", path: "users", parameters: parameters, constructingBodyWith: { formData in })

        BitweaverHTTPClient.prepareRequestHeaders(putRequest)

        if let operation = AFJSONRequestOperation(request: putRequest as! URLRequest, success: { request, response, JSON in
                self.load(fromRemoteProperties: JSON as? [String : Any])
                APPDELEGATE.authenticationSuccess()
            }, failure: { request, response, error, JSON in
                APPDELEGATE.registrationFailure("Registration failed.\n\n\(BitweaverHTTPClient.errorMessage(withResponse: response, urlRequest: request, json: JSON as? [AnyHashable : Any]) ?? "")")
        }) {
            OperationQueue().addOperation(operation)
        }
    }

    func authenticate(_ authLogin: String?, withPassword authPassword: String?) {

        APPDELEGATE.authLogin = authLogin ?? ""
        APPDELEGATE.authPassword = authPassword ?? ""

        if let operation = AFJSONRequestOperation(request: BitweaverHTTPClient.request(withPath: "users/authenticate") as URLRequest!, success: { request, response, JSON in
                // Set all cookies so subsequent requests pass on info
                var cookies: [HTTPCookie]? = nil
                if let aFields = response?.allHeaderFields as? [String : String], let anUri = URL(string: APPDELEGATE.apiBaseUri ?? "") {
                    cookies = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
                }

                for cookie: HTTPCookie? in cookies ?? [] {
                    if let aCookie = cookie {
                        HTTPCookieStorage.shared.setCookie(aCookie)
                    }
                }

                self.load(fromRemoteProperties: JSON as? [String : Any])
                APPDELEGATE.authenticationSuccess()

                // Send a notification event user has just logged in.
                NotificationCenter.default.post(name: NSNotification.Name("UserAuthenticated"), object: self)

                if self.callbackSelectorName != nil {
                    self.callbackObject?.perform(NSSelectorFromString(self.callbackSelectorName))
                    self.callbackObject = nil
                    self.callbackSelectorName = ""
                }

            }, failure: { request, response, error, JSON in
                APPDELEGATE.authenticationFailure(with: request, response: response, error: error, json: JSON)
        }) {
            OperationQueue().addOperation(operation)
        }
    }

    func logout() {
        APPDELEGATE.authLogin = ""
        APPDELEGATE.authPassword = ""
        if let properties = getAllPropertyMappings() {
            for (key,value) in properties {
                if let varName = properties[key] {
                    if responds(to: NSSelectorFromString(varName)) {
                        setValue(nil, forKey: varName ?? "")
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

    override func load(fromRemoteProperties remoteHash: [String : Any]?) {
        super.load(fromRemoteProperties: remoteHash)
        NotificationCenter.default.post(name: NSNotification.Name("UserLoaded"), object: self)
    }
}
