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
    @objc dynamic var avatarUri: URL?
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

	var cookieArray: [HTTPCookie] = []
	
    // Prevent multiple
    static let active = BitweaverUser()

    override var primaryId: String? { return userId?.stringValue }

    override func initProperties() {
        contentTypeGuid = "bituser"
		let completion: (Bool, String) -> Void = { isSuccess, message in
		}
		verifySession(completion: completion)
	}
	
    override func getRemotePropertyMappings() -> [String: String] {
        var mappings = [
            "user_id": "userId",
            "login": "login",
            "last_login": "lastLogin",
            "registration_date": "registrationDate",
            "avatar_uri": "avatarUri"
/*
            "portrait_path" : "portraitPath",
            "portrait_url" : "portraitUrl",
            "avatar_path" : "avatarPath",
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
    
    func getProfilePicture() -> BWImage {
        var ret = BWImage()
        if let avatarPath = avatarUri {
           do {
               let avatarData = try Data.init(contentsOf: avatarPath)
               if let userImage = BWImage.init(data: avatarData) {
                   ret = userImage
               }
           } catch {}
        }
        return ret
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

	func register(_ authLogin: String, _ authPassword: String, handler: BaseBitweaverLoginViewController, saveToKeyChain: Bool) {

        // Assume login was email field, update here for registration
        email = authLogin

        var parameters: [String: String] = [:]
        let properties = getSendablePropertyMappings()
        for (key, name) in properties {
            parameters[key] = value(forKey: name) as? String
        }
		parameters["register"] = "y"
        parameters["email"] = authLogin
        parameters["password"] = authPassword
        parameters["real_name"] = BitweaverAppBase.deviceUsername

        let headers = BitweaverAppBase.httpHeaders()

        Alamofire.request(BitweaverAppBase.apiBaseUri+"api/users/register",
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
						self?.authenticate(authLogin: authLogin, authPassword: authPassword, handler: handler, saveToKeyChain: saveToKeyChain)
                    case 400 ... 499:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                            print("Data: \(utf8Text)")
                        }
                        errorMessage = "Registration failed. \n"+BitweaverAppBase.httpError( response: response, request: response.request )
                    case 500:
                        errorMessage = "Internal server error. Contact support"
                    default:
                        errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                    }
                }
                handler.authenticationResponse(success: ret, message: errorMessage )
        }
    }

    func authenticate( authLogin: String, authPassword: String, handler: BaseBitweaverLoginViewController, saveToKeyChain: Bool ) {

        var headers = BitweaverAppBase.httpHeaders()
        let credentialData = "\(authLogin):\(authPassword)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        headers["Authorization"] = "Basic \(base64Credentials)"

        Alamofire.request(BitweaverAppBase.apiBaseUri+"api/users/authenticate",
                          method: .post,
						  parameters: ["rme": "on"], // enable remember me. Very important so your cookie doesn't die
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
                        BitweaverAppBase.authLogin = authLogin
                        BitweaverAppBase.authPassword = authPassword

                        // Set all cookies so subsequent requests pass on info
						self?.cookieArray.removeAll()
                        if let aFields = response.response?.allHeaderFields as? [String: String], let anUri = URL(string: BitweaverAppBase.apiBaseUri ) {
                            self?.cookieArray = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
                        }

                        if response.response?.mimeType == "application/json" {
                            let userJSON = JSON(response.result.value as Any)
							// .load will send a notification event user has just logged in.
                            self?.load(fromJSON: userJSON)
							if let accountEmail = self?.email {
								if saveToKeyChain {
									KeychainHelper.savePassword(service: "keyChainService", account: accountEmail, data: authPassword)
								} else {
									KeychainHelper.removePassword(service: "keyChainService", account: accountEmail)
									KeychainHelper.removeAccount(service: "keyChainService")
								}
							}
                        }
                        ret = true

                    case 400 ... 499:
                        if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                            print("Data: \(utf8Text)")
                        }
                        // errorMessage = gBitSystem.httpError( response:response, request:response.request! )!
                        errorMessage = String(format: "Invalid login and password. Perhaps you need to register?\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                        //gBitSystem.authenticationFailure(with: request, response: response, error: response.error, json: response.result.value)
                    case 500:
                        errorMessage = "Internal server error. Contact support"
                    default:
                        errorMessage = String(format: "Unexpected error.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
                    }
                    handler.authenticationResponse(success: ret, message: errorMessage )
                }
        }
    }

	func verifySession( completion: @escaping (_ success: Bool, _ message: String) -> Void ) {
		let localCompletion: (Int, JSON, String ) -> Void = {statusCode, json, message in
			let success = statusCode >= 200 && statusCode <= 399
			if success {
				self.load(fromJSON: json)
			}
			completion( success, message )
		}
		
		sendRestRequest(uri: BitweaverAppBase.apiBaseUri+"api/users/authenticate", method: .get, completion: localCompletion)
	}
	
    func logout( completion: @escaping (_ success: Bool, _ message: String) -> Void ) {
        BitweaverAppBase.authLogin = ""
        BitweaverAppBase.authPassword = ""
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
		
		let localCompletion: (Int, JSON, String ) -> Void = {statusCode, json, message in
			let success = statusCode >= 200 && statusCode <= 399
			// fail or not, we don't care. We've already unset all member variables
			completion( success, message )
		}

		sendRestRequest(uri: BitweaverAppBase.apiBaseUri+"api/users/authenticate", method: .delete, completion: localCompletion)
		
		cookieArray.removeAll()
		NotificationCenter.default.post(name: NSNotification.Name("UserUnloaded"), object: self)
    }
	
	private func sendRestRequest( uri: String, method: HTTPMethod, completion: @escaping (_ statusCode: Int, _ json: JSON, _ message: String) -> Void ) {
		let headers = BitweaverAppBase.httpHeaders()
		Alamofire.request(	uri,
							  method: method,
							  encoding: URLEncoding.default,
							  headers: headers)
			.validate(statusCode: 200..<500)
			.responseJSON { [weak self] response in
				
				var errorMessage: String = ""
				
				if let statusCode = response.response?.statusCode {
					let respJson = JSON(response.result.value as Any)

					switch statusCode {
					case 200 ... 399:
						// Set all cookies so subsequent requests pass on info
						self?.cookieArray.removeAll()
						if let aFields = response.response?.allHeaderFields as? [String: String], let anUri = URL(string: BitweaverAppBase.apiBaseUri ) {
							self?.cookieArray = HTTPCookie.cookies(withResponseHeaderFields: aFields, for: anUri)
						}
					case 400 ... 499:
						if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
							print("Data: \(utf8Text)")
						}
						
						// errorMessage = gBitSystem.httpError( response:response, request:response.request! )!
						errorMessage = String(format: "Server request failed.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
					//gBitSystem.authenticationFailure(with: request, response: response, error: response.error, json: response.result.value)
					default:
						errorMessage = String(format: "Unexpected error. Most likely there was an issue on the remote server. Out there, somewhere some engineer just got paged, and now (s)he is sad.\n(EC %ld %@)", Int(response.response?.statusCode ?? 0), response.request?.url?.host ?? "")
					}
					completion(statusCode, respJson, errorMessage)
				}
			}
	}

    override func load(fromJSON json: JSON) {
        super.load(fromJSON: json)
        NotificationCenter.default.post(name: NSNotification.Name("UserLoaded"), object: self)
    }
}

class KeychainHelper: NSObject {
	
	static let kSecClassValue = NSString(format: kSecClass)
	static let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
	static let kSecValueDataValue = NSString(format: kSecValueData)
	static let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
	static let kSecAttrServiceValue = NSString(format: kSecAttrService)
	static let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
	static let kSecReturnDataValue = NSString(format: kSecReturnData)
	static let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)
	
	static func updatePassword(service: String, account: String, data: String) {
		guard let dataFromString =  data.data(using: String.Encoding.utf8, allowLossyConversion: false)
			else {return}
		let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue])
		
		let status = SecItemUpdate(keychainQuery as CFDictionary, [kSecValueDataValue: dataFromString] as CFDictionary)
		
		if status != errSecSuccess {
            if #available(iOS 11.3, *) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("Read failed: \(err)")
                }
            } else {
                // Fallback on earlier versions
            }
		}
	}// end update password
	
	static func removePassword(service: String, account: String) {
		let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue])
		
		let status = SecItemDelete(keychainQuery as CFDictionary)
		if status != errSecSuccess {
            if #available(iOS 11.3, *) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("Remove failed: \(err)")
                }
            } else {
                // Fallback on earlier versions
            }
		}
	}
	
	static func savePassword(service: String, account: String, data: String) {
		if let dataFromString = data.data(using: String.Encoding.utf8, allowLossyConversion: false) {
			
			let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, dataFromString],
																		 forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue])
			let status = SecItemAdd(keychainQuery as CFDictionary, nil)
			
			if status != errSecSuccess {    // Always check the status
                if #available(iOS 11.3, *) {
                    if let err = SecCopyErrorMessageString(status, nil) {
                        if (err as String) == "The specified item already exists in the keychain" {
                            updatePassword(service: service, account: account, data: data)
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
			}
		}
	}
	
	static func removeAccount(service: String = "keyChainService") {
		let query: [String: Any] = [kSecClass as String: kSecClassGenericPasswordValue,
									kSecAttrServiceValue as String: service,
									kSecMatchLimit as String: kSecMatchLimitOne,
									kSecReturnAttributes as String: true,
									kSecReturnData as String: true]
		let status = SecItemDelete(query as CFDictionary)
		if status != errSecSuccess {
            if #available(iOS 11.3, *) {
                if let err = SecCopyErrorMessageString(status, nil) {
                    print("Remove failed: \(err)")
                }
            } else {
                // Fallback on earlier versions
            }
		}
	}
	
	static func loadAccount(service: String = "keyChainService") -> String {
		let query: [String: Any] = [kSecClass as String: kSecClassGenericPasswordValue,
									kSecAttrServiceValue as String: service,
									kSecMatchLimit as String: kSecMatchLimitOne,
									kSecReturnAttributes as String: true,
									kSecReturnData as String: true]
		var item: CFTypeRef?
		
		SecItemCopyMatching(query as CFDictionary, &item)
		if let existingItem = item as? [String: Any], let account = existingItem[kSecAttrAccount as String] as? String {
			return account
		}
		return ""
	}
	
	static func loadPassword(service: String, account: String) -> String? {
		let keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, account, kCFBooleanTrue, kSecMatchLimitOneValue],
																	 forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])
		
		var dataTypeRef: AnyObject?
		
		let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
		var contentsOfKeychain: String?
		
		if status == errSecSuccess {
			if let retrievedData = dataTypeRef as? Data {
				contentsOfKeychain = String(data: retrievedData, encoding: String.Encoding.utf8)
			}
		} else {
			print("Nothing was retrieved from the keychain. Status code \(status)")
		}
		
		return contentsOfKeychain
	}
}
