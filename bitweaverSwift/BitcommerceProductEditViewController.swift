//
//  BitcommerceProductViewController.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/26/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

class BitcommerceProductViewController: BWViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    func handle(error: Error) {
        // You should add some real error handling code.
        print(error)
        DispatchQueue.main.async {
            NSAlert(error: error).runModal()
        }
    }
}
