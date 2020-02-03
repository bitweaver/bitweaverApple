//
//  BitweaverUtilitiesCocoa.swift
//  PrestoPhoto
//
//  Created by Caleb Mitcler on 1/15/20.
//  Copyright © 2020 PrestoPhoto. All rights reserved.
//

import Foundation
import Cocoa

extension BWViewController {
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func unloadView( view: BWView? ) {
        view?.viewWillMove(toWindow: nil)
        view?.removeFromSuperview()
    }
    
    func unloadViewController( viewController: BWViewController? ) {
        unloadView(view: viewController?.view)
        viewController?.removeFromParent()
    }

    func handle(error: Error) {
        // You should add some real error handling code.
        print(error)
        DispatchQueue.main.async {
            NSAlert(error: error).runModal()
        }
    }
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

extension NSTabView {
    func selectedTabViewItemIndex() -> Int {
        var ret = 0
        if let selectedTabViewItem = selectedTabViewItem {
            ret = indexOfTabViewItem(selectedTabViewItem)
        }
        return ret
    }
}

extension NSSize {
    var ratio: CGFloat { return width / height }
}

extension BWImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)

        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }
    
    @discardableResult
    func saveAsPNG(url: URL) -> Bool {
        guard let tiffData = tiffRepresentation else {
            print("failed to get tiffRepresentation. url: \(url)")
            return false
        }
        let imageRep = NSBitmapImageRep(data: tiffData)
        guard let imageData = imageRep?.representation(using: .png, properties: [:]) else {
            print("failed to get PNG representation. url: \(url)")
            return false
        }
        do {
            try imageData.write(to: url)
            return true
        } catch {
            print("failed to write to disk. url: \(url)")
            return false
        }
    }
    
    @discardableResult
    func toDataJPG() -> Data? {
        guard let tiffData = tiffRepresentation else {
            print("failed to get tiffRepresentation.")
            return nil
        }
        let imageRep = NSBitmapImageRep(data: tiffData)
        guard let imageData = imageRep?.representation(using: .jpeg, properties: [:]) else {
            print("failed to get JPG representation.")
            return nil
        }
        return imageData
    }
    
    @discardableResult
    func saveAsJPG(url: URL) -> Bool {
        do {
            guard let imageData = toDataJPG() else {return false}
            try imageData.write(to: url)
            return true
        } catch {
            BitweaverAppBase.log(level: BitweaverAppBase.LogLevel.Error, "failed to write to disk. url: %@", url.absoluteString)
            return false
        }
    }
    
    @discardableResult
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
}

extension CGImage {
    func saveAsJPG(url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, self, nil)
        return CGImageDestinationFinalize(destination)
    }
}

extension BWColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if colorSpace == .sRGB {
            getRed(&r, green: &g, blue: &b, alpha: &a)
        } else {
            if let sRGB = self.usingColorSpace(.sRGB) {
                sRGB.getRed(&r, green: &g, blue: &b, alpha: &a)
            }
        }

        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

        return String(format: "#%06x", rgb)
    }
}

extension NSFont {
    convenience init?(cssValue: String) {
        var fontName = "Helvetica"
        var fontSize: CGFloat = 18.0
        
        // Need to parse font here. This is very inflexible and only matches toCssString() data.
        let stringComponents = cssValue.components(separatedBy: " ")
        if stringComponents.count > 0 {
            if stringComponents[0] == "font:" {
                if stringComponents.count == 3 {
                    fontName = stringComponents[2]
                    if let pointSize = NumberFormatter().number(from: stringComponents[1].filter("01234567890.".contains)) {
                        fontSize = CGFloat(pointSize.floatValue)
                    }
                }
            }
        }

        self.init(name: fontName, size: fontSize)
    }
    
    func toCssString() -> String {
        let ret = "font: "+pointSize.description+"pt "+fontName
        return ret
    }
}
