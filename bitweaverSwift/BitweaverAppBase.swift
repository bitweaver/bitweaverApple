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

class BitweaverAppBase: NSObject {
    var authLogin: String = ""
    var authPassword: String = ""
}

protocol BitweaverApp {
    func showAuthenticationDialog()
    func authenticationSuccess()
    func authenticationFailure(with request: URLRequest?, response: HTTPURLResponse?, error: Error?, json: Any?)
    func registrationFailure(_ failureMessage: String?)
}
