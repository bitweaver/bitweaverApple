//
//  BitweaverLogoutViewController.swift
//
//  Created by Christian Fowler on 10/1/18.
//  Copyright © 2020 bitweaver.org LGPL license.
//

import Cocoa

class BitweaverLogoutViewController: BWViewController {

    @IBOutlet weak var userName: NSTextField!
    @IBOutlet weak var userImage: NSImageView!
    @IBOutlet weak var email: NSTextField!
    @IBOutlet weak var registeredDate: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        userName.stringValue = gBitUser.displayName
        email.stringValue = gBitUser.email ?? ""
        registeredDate.stringValue = "Registered "+(gBitUser.registrationDate?.longString ?? "")
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(nil)
    }

    @IBAction func logout(_ sender: Any) {
		let completion: (Bool, String) -> Void = {success, message in 
            self.dismiss(nil)
        }

        gBitUser.logout(completion: completion)
        dismiss(nil)
    }

    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }
    
}
