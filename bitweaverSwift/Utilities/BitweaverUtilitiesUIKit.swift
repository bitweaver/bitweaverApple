//
//  BitweaverUtilitiesUIKit.swift
//  PrestoPhoto iOS
//
//  Created by Caleb Mitcler on 1/15/20.
//  Copyright © 2020 PrestoPhoto. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

extension BWViewController {
    
}

extension URL {
    func mimeType() -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}
