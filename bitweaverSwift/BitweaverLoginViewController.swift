//
//  BitweaverLoginViewController.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/22/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

class BitweaverLoginViewController: BaseBitweaverLoginViewController {

    @IBOutlet weak var emailInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var feedbackLabel: NSTextField!
    @IBOutlet weak var signinButton: NSButton!
    @IBOutlet weak var connectProgress: NSProgressIndicator!
	
	@IBOutlet var rememberPasswordButton: NSButton!
	var shouldSavePassword: Bool {
		return rememberPasswordButton.state == NSControl.StateValue.on
	}

    @IBAction func signInButtonClicked(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            signIn( authLogin: self.emailInput.stringValue, authPassword: self.passwordInput.stringValue, handler: self, saveToKeyChain: self.shouldSavePassword)
        } else {
            feedbackLabel.stringValue = feedBackErrorMessage
        }
    }
    
    @IBAction func registerButtonClicked(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            register( emailInput.stringValue, passwordInput.stringValue, handler: self, saveToKeyChain: shouldSavePassword)
        } else {
            feedbackLabel.stringValue = feedBackErrorMessage
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        dismiss(nil)
    }
    
    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }

    override func authenticationResponse(success: Bool, message: String) {
        if success {
            dismiss(nil)
        } else {
            feedbackLabel.stringValue = message
        }
    }

    override func registrationResponse( success: Bool, message: String ) {
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
