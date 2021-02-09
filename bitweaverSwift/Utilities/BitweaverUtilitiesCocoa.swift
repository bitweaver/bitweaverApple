//
//  BitweaverUtilitiesCocoa.swift
//
//  Created by Caleb Mitcler on 1/15/20.
//  Copyright © 2020 bitweaver.org LGPL license.
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

extension NSImage {
    // Support for NSImage.init(cgImage)
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: CGSize.zero)
    }
    
    convenience init?(contentsOf path: String) {
        let bundleUrl = URL.init(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: bundleUrl.path) {
            self.init(contentsOf: bundleUrl)
        } else {
            self.init()
        }
    }
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
