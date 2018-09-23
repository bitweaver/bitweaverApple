//
//  BitweaverLoginViewController.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/22/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

class BitweaverLoginViewController: NSViewController {
    @IBOutlet weak var emailInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var feedbackLabel: NSTextField!
    @IBOutlet weak var signinButton: NSButton!
    
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(nil)
    }
    @IBAction func signin(_ sender: Any) {
        if emailInput.stringValue.count > 0 && passwordInput.stringValue.count > 0 {
            gBitUser.authenticate( authLogin:emailInput.stringValue, authPassword: passwordInput.stringValue, handler:self)
        } else {
            feedbackLabel.stringValue = "Please enter your email and password used to login to www.prestophoto.com"
        }
    }
    
    func authenticationResponse( success:Bool, message:String, response:HTTPURLResponse ) {
        if( success ) {
            dismiss(nil)
        } else {
            feedbackLabel.stringValue = message
        }
    }
    
    func registrationResponse( success:Bool, message:String, response:HTTPURLResponse ) {
        if( success ) {
            dismiss(nil)
        } else {
            feedbackLabel.stringValue = message
        }
    }
    
    override func viewDidLoad() {
        signinButton.keyEquivalent = "\r";
        signinButton.isHighlighted = true
    }
}

