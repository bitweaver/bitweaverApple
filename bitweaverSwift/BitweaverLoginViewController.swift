//
//  BitweaverLoginViewController.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/22/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

class BitweaverLoginViewController: BWViewController {

	var loginCompletion: (() -> Void)?
	
    @IBOutlet weak var emailInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var feedbackLabel: NSTextField!
    @IBOutlet weak var signinButton: NSButton!
    @IBOutlet weak var connectProgress: NSProgressIndicator!
	
	@IBOutlet var rememberPasswordButton: NSButton!
	var shouldSavePassword: Bool {
		return rememberPasswordButton.state == NSControl.StateValue.on
	}

    @IBAction func cancel(_ sender: Any) {
        dismiss(nil)
    }

    @IBAction func signin(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            connectProgress.startAnimation(sender)
			let completion: (Bool, String) -> Void = { [self] isSuccess, message in
				if !isSuccess {
					gBitUser.authenticate( authLogin: self.emailInput.stringValue, authPassword: self.passwordInput.stringValue, handler: self, saveToKeyChain: self.shouldSavePassword)
				}
			}
			gBitUser.verifySession(completion: completion)
        } else {
            feedbackLabel.stringValue = "Please enter your email and password used to login to \n" + gBitSystem.apiBaseUri
        }
    }

    @IBAction func register(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
			gBitUser.register( emailInput.stringValue, passwordInput.stringValue, handler: self, saveToKeyChain: shouldSavePassword)
        } else {
            feedbackLabel.stringValue = "Please enter your email and password used to login to \n" + gBitSystem.apiBaseUri
        }

    }

    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }

    func authenticationResponse(success: Bool, message: String) {
        if success {
            dismiss(nil)
        } else {
            feedbackLabel.stringValue = message
        }
    }

    func registrationResponse( success: Bool, message: String ) {
        if success {
            dismiss(nil)
        } else {
            feedbackLabel.stringValue = message
        }
    }

    override func viewDidLoad() {
		let account = KeychainHelper.loadAccount()
		emailInput.stringValue = account
		if let password = KeychainHelper.loadPassword(service: "keyChainService", account: account) {
			passwordInput.stringValue = password
		}

    	connectProgress.stopAnimation(nil)
        signinButton.keyEquivalent = "\r"
        signinButton.isHighlighted = true
    }
}
