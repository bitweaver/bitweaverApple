//
//  BitweaverUtilities.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/27/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

import Cocoa

// App wide alias for iOS and macOS cross platform convenience
typealias BWImage = NSImage
typealias BWViewController = NSViewController
typealias BWColor = NSColor

extension NSObject {
    var myClassName: String {
        return NSStringFromClass(type(of: self))
    }
}

extension BWImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        
        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }
    //    convenience init?(named name: String) {
    //        self.init(named: Name(name))
    //    }
}

extension BWColor {
    convenience init(hexString:String) {
        let hexString:String = hexString.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}
