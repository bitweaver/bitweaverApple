//
//  BaseBitweaverLoginViewController.swift
//  PrestoPhoto
//
//  Created by Caleb Mitcler on 2/3/20.
//  Copyright © 2020 PrestoPhoto. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#else
import Cocoa
#endif

class BaseBitweaverLoginViewController: BWViewController {
    
    var loginCompletion: (() -> Void)?
    
    func signIn(authLogin: String, authPassword: String, handler: BaseBitweaverLoginViewController, saveToKeyChain: Bool) {
        let completion: (Bool, String) -> Void = { [self] isSuccess, message in
            if !isSuccess {
                gBitUser.authenticate( authLogin: authLogin, authPassword: authPassword, handler: handler, saveToKeyChain: saveToKeyChain)
            }
        }
        gBitUser.verifySession(completion: completion)
    }
    
    func register(_ authLogin: String, _ authPassword: String, handler: BaseBitweaverLoginViewController, saveToKeyChain: Bool) {
        gBitUser.register( authLogin, authPassword, handler: handler, saveToKeyChain: saveToKeyChain)
    }
    
    func authenticationResponse(success: Bool, message: String) {

    }

    func registrationResponse( success: Bool, message: String ) {

    }
    
    
}
