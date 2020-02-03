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
    
    func authenticationResponse(success: Bool, message: String) {

    }

    func registrationResponse( success: Bool, message: String ) {

    }
}
