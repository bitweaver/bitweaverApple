//
//  BitweaverLoginViewController.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/22/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

class BitweaverLoginViewController: BWViewController {
    @IBOutlet weak var emailInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var feedbackLabel: NSTextField!
    @IBOutlet weak var signinButton: NSButton!
    @IBOutlet weak var connectProgress: NSProgressIndicator!

    @IBAction func cancel(_ sender: Any) {
        dismiss(nil)
    }

    @IBAction func signin(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            connectProgress.startAnimation(sender)
            gBitUser.authenticate( authLogin: emailInput.stringValue, authPassword: passwordInput.stringValue, handler: self)
        } else {
            feedbackLabel.stringValue = "Please enter your email and password used to login to \n" + gBitSystem.apiBaseUri
        }
    }

    @IBAction func register(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            gBitUser.register( emailInput.stringValue, passwordInput.stringValue, handler: self)
        } else {
            feedbackLabel.stringValue = "Please enter your email and password used to login to \n" + gBitSystem.apiBaseUri
        }

    }

    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }

    func authenticationResponse( success: Bool, message: String ) {
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
    connectProgress.stopAnimation(nil)
        signinButton.keyEquivalent = "\r"
        signinButton.isHighlighted = true
    }
}
