//
//  BitweaverUtilities.swift
//
//  Created by Christian Fowler on 9/27/18.
//  Copyright © 2020 bitweaver.org LGPL license.
//

// App wide alias for iOS and macOS cross platform convenience

#if os(iOS)
import UIKit

typealias BWImage = UIImage
typealias BWView = UIView
typealias BWViewController = UIViewController
typealias BWColor = UIColor
typealias BWFont = UIFont
#elseif os(macOS)
import Cocoa

typealias BWImage = NSImage
typealias BWView = NSView
typealias BWViewController = NSViewController
typealias BWColor = NSColor
typealias BWFont = NSFont
#endif

import WebKit
extension NSObject {
    var myClassName: String {
        return NSStringFromClass(type(of: self))
    }
}

public extension Int {

    /// Returns a random Int point number between 0 and Int.max.
    static var random: Int {
        return Int.random(n: Int.max)
    }

    /// Random integer between 0 and n-1.
    ///
    /// - Parameter n:  Interval max
    /// - Returns:      Returns a random Int point number between 0 and n max
    static func random(n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }

    ///  Random integer between min and max
    ///
    /// - Parameters:
    ///   - min:    Interval minimun
    ///   - max:    Interval max
    /// - Returns:  Returns a random Int point number between 0 and n max
    static func random(min: Int, max: Int) -> Int {
        return Int.random(n: max - min + 1) + min

    }
}

extension Double {

    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    public static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }

    /// Random double between 0 and n-1.
    ///
    /// - Parameter n:  Interval max
    /// - Returns:      Returns a random double point number between 0 and n max
    public static func random(min: Double, max: Double) -> Double {
        return Double.random * (max - min) + min
    }
    
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }}

extension Float {

    /// Returns a random floating point number between 0.0 and 1.0, inclusive.
    public static var random: Float {
        return Float(arc4random()) / Float.greatestFiniteMagnitude
    }

    /// Random float between 0 and n-1.
    ///
    /// - Parameter n:  Interval max
    /// - Returns:      Returns a random float point number between 0 and n max
    public static func random(min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
}

import CommonCrypto

extension URL {
	func md5() -> Data? {
		let bufferSize = 1024 * 1024
		
		do {
			// Open file for reading:
			let file = try FileHandle(forReadingFrom: self)
			defer {
				file.closeFile()
			}
			
			// Create and initialize MD5 context:
			var context = CC_MD5_CTX()
			CC_MD5_Init(&context)
			
			// Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
			while autoreleasepool(invoking: {
				let data = file.readData(ofLength: bufferSize)
				if data.count > 0 {
					data.withUnsafeBytes {
						_ = CC_MD5_Update(&context, $0, numericCast(data.count))
					}
					return true // Continue
				} else {
					return false // End of file
				}
			}) { }
			
			// Compute the MD5 digest:
			var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
			digest.withUnsafeMutableBytes {
				_ = CC_MD5_Final($0, &context)
			}
			
			return digest
			
		} catch {
			print("Cannot open file:", error.localizedDescription)
			return nil
		}
	}

	func sha256() -> Data? {
		do {
			let bufferSize = 1024 * 1024
			// Open file for reading:
			let file = try FileHandle(forReadingFrom: self)
			defer {
				file.closeFile()
			}
			
			// Create and initialize SHA256 context:
			var context = CC_SHA256_CTX()
			CC_SHA256_Init(&context)
			
			// Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
			while autoreleasepool(invoking: {
				// Read up to `bufferSize` bytes
				let data = file.readData(ofLength: bufferSize)
				if data.count > 0 {
					data.withUnsafeBytes {
						_ = CC_SHA256_Update(&context, $0, numericCast(data.count))
					}
					// Continue
					return true
				} else {
					// End of file
					return false
				}
			}) { }
			
			// Compute the SHA256 digest:
			var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
			digest.withUnsafeMutableBytes {
				_ = CC_SHA256_Final($0, &context)
			}
			
			return digest
		} catch {
			print(error)
			return nil
		}
	}
    
    func creationDate() -> Date? {
        var ret: Date?
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            ret = fileAttributes[FileAttributeKey.creationDate] as? Date
        } catch {
            print("error getting creationDate from url " + error.localizedDescription)
        }
        return ret
    }
    
    func lastModifiedDate() -> Date? {
        var ret: Date?
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: self.path) {
            ret = fileAttributes[FileAttributeKey.modificationDate] as? Date
        }
        return ret
    }
    
    func fileSize() -> Int? {
        var ret: Int?
        do {
            let resources = try self.resourceValues(forKeys: [.fileSizeKey])
            ret = resources.fileSize
        } catch {
            print("Error: \(error)")
        }
        return ret
    }
    
    /*
     if pagesUrl.isNewerThanFile(url: pdfUrl) {
        pages has been modified since the pdf was last generated
        we need to generate a new pdf
     }
     */
    func isNewerThanFile(at url: URL) -> Bool {
        guard let sourceLastModified = lastModifiedDate(),
            let destLastModified = url.lastModifiedDate()
            else {return false}
        if sourceLastModified.timeIntervalSince1970 > destLastModified.timeIntervalSince1970 {
            return true
        }
        return false
    }
    
    func isInTrash() -> Bool {
        return path.contains("/.Trash/")
    }
    
    func isReadable() -> Bool {
        return FileManager.default.isReadableFile(atPath: self.path)
    }
}

extension Data {
	func digest() -> String {
		let hexDigest = self.map { String(format: "%02hhx", $0) }.joined()
		return hexDigest
	}
}

extension Date {
    var shortDate: String {
        return DateFormatter.localizedString(
            from: self,
            dateStyle: .short,
            timeStyle: .none)
    }
    var shortString: String {
        return DateFormatter.localizedString(
            from: self,
            dateStyle: .short,
            timeStyle: .short)
    }
    var mediumString: String {
        return DateFormatter.localizedString(
            from: self,
            dateStyle: .medium,
            timeStyle: .medium)
    }
    var longString: String {
        return DateFormatter.localizedString(
            from: self,
            dateStyle: .long,
            timeStyle: .long)
    }
    
    func updateYear(year: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([Calendar.Component.month, Calendar.Component.day, Calendar.Component.year], from: self)
        components.setValue(year, for: Calendar.Component.year)
        return calendar.date(from: components)
    }

	func convertTimeZone(to toTimeZone: TimeZone, from fromTimeZone: TimeZone = .current) -> Date {
		let delta = TimeInterval(toTimeZone.secondsFromGMT(for: self) - fromTimeZone.secondsFromGMT(for: self))
		return addingTimeInterval(delta)
	}
}

extension Formatter {
	static let iso8601: DateFormatter = {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
		return formatter
	}()
}

extension String {
    
    func md5() -> String {
        if let messageData = data(using: .utf8) {
            var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            _ = digestData.withUnsafeMutableBytes {digestBytes in
                messageData.withUnsafeBytes {messageBytes in
                    CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
                }
            }
            return digestData.base64EncodedString()
        } else {
            return ""
    	}
    }
    
    func toDateISO8601() -> Date? {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return RFC3339DateFormatter.date(from: self)
    }
    
    func verifyHexColor(default defaultColor: String) -> String {
        return self.matches( "#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})" ) ? self : defaultColor
    }
    
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    var humanizedAppUri: String {
        return self.replacingOccurrences(of: "https://app.", with: "https://www.")
    }
	
	var rtfStringToAttributedString: NSAttributedString? {
		guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return nil }
		guard let rtfString = try? NSMutableAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) else { return nil }
		return rtfString
	}
	
	var stripRTF: String {
		let attrString = self.rtfStringToAttributedString
		if let cleanString = attrString?.string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) {
			return cleanString
		}
		return ""
	}
	
	var stripHTML: String {
		guard let data = self.data(using: .utf8) else {
			return ""
		}
		let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
			.documentType: NSAttributedString.DocumentType.html,
			.characterEncoding: String.Encoding.utf8.rawValue
		]
		do {
			let attrString = try NSAttributedString.init(data: data, options: options, documentAttributes: nil)
			let cleanString = attrString.string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
			return cleanString
		} catch {}
		return ""
	}

    var isRtfString: Bool {
        return rtfStringToAttributedString != nil
    }
	
	var isValidEmail: Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
		let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
		return emailPred.evaluate(with: self)
	}
    
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)

        let regex = try? NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex?.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard data.count > 0 else { return nil }

        return data
    }
}

extension Date {
    func toStringISO8601() -> String? {
        let RFC3339DateFormatter = DateFormatter()
        RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return RFC3339DateFormatter.string(from: self)
    }
}

extension BWViewController {
    func clearChildren() {
        children.forEach({
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        })
    }
}

extension BWView {
    func clearChildren() {
        subviews.forEach({
            $0.removeFromSuperview()
        })
    }
}

extension CGPoint {
    func scale(_ scaleSize: CGSize) -> CGPoint {
        return CGPoint.init(x: self.x*scaleSize.width, y: self.y*scaleSize.height)
    }
    
    func scale(_ scaleSize: CGFloat) -> CGPoint {
        return CGPoint.init(x: self.x*scaleSize, y: self.y*scaleSize)
    }
}

extension CGSize {
    func scale(_ scaleSize: CGSize) -> CGSize {
        return CGSize.init(width: self.width*scaleSize.width, height: self.height*scaleSize.height)
    }
    
    func scale(_ scaleSize: CGFloat) -> CGSize {
        return CGSize.init(width: self.width*scaleSize, height: self.height*scaleSize)
    }
}

extension BWColor {
    convenience init(hexValue: String) {
        var alphaValue = 1.0
        let cleanString = hexValue.replacingOccurrences(of: "#", with: "")
        var colorString = cleanString
        if cleanString.count == 8 {
            let alphaHex = cleanString.suffix(2)
            alphaValue = Double(UInt8(alphaHex, radix: 16) ?? 0) / 255.0
            colorString = String(cleanString.prefix(6))
        }
        
        var checkedHex: String = colorString
        if checkedHex.isEmpty {
            checkedHex = "FFFFFF"
        }
        let scanner = Scanner(string: checkedHex)

        var color: UInt32 = 0
        scanner.scanHexInt32(&color)

        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask

        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(calibratedRed: red, green: green, blue: blue, alpha: CGFloat(alphaValue))
    }
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if let rgbColor = self.usingColorSpaceName(.calibratedRGB) {
            rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        let wholeAlpha = a * 255.0
        var alphaStr = String(Int(wholeAlpha), radix: 16)
        if wholeAlpha < 16.0 {
            alphaStr = "0" + alphaStr
        }        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        let rgbStr = String(format: "#%06x", rgb)
        
        return rgbStr.appending(alphaStr)
    }
}

extension NSRegularExpression {
	convenience init(_ pattern: String) {
		do {
			try self.init(pattern: pattern)
		} catch {
			preconditionFailure("Illegal regular expression: \(pattern).")
		}
	}

	static func matches(for pattern: String, in text: String) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: pattern)
			let nsString = text as NSString
			let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
			return results.map { nsString.substring(with: $0.range)}
		} catch let error {
			print("invalid regex: \(error.localizedDescription)")
			return []
		}
	}
}

struct Keycode {
    
    // Layout-independent Keys
    // eg.These key codes are always the same key on all layouts.
    static let returnKey: UInt16 = 0x24
    static let enter: UInt16 = 0x4C
    static let tab: UInt16 = 0x30
    static let space: UInt16 = 0x31
    static let delete: UInt16 = 0x33
    static let escape: UInt16 = 0x35
    static let command: UInt16 = 0x37
    static let shift: UInt16 = 0x38
    static let capsLock: UInt16 = 0x39
    static let option: UInt16 = 0x3A
    static let control: UInt16 = 0x3B
    static let rightShift: UInt16 = 0x3C
    static let rightOption: UInt16 = 0x3D
    static let rightControl: UInt16 = 0x3E
    static let leftArrow: UInt16 = 0x7B
    static let rightArrow: UInt16 = 0x7C
    static let downArrow: UInt16 = 0x7D
    static let upArrow: UInt16 = 0x7E
    static let volumeUp: UInt16 = 0x48
    static let volumeDown: UInt16 = 0x49
    static let mute: UInt16 = 0x4A
    static let help: UInt16 = 0x72
    static let home: UInt16 = 0x73
    static let pageUp: UInt16 = 0x74
    static let forwardDelete: UInt16 = 0x75
    static let end: UInt16 = 0x77
    static let pageDown: UInt16 = 0x79
    static let function: UInt16 = 0x3F
    static let f1: UInt16 = 0x7A
    static let f2: UInt16 = 0x78
    static let f4: UInt16 = 0x76
    static let f5: UInt16 = 0x60
    static let f6: UInt16 = 0x61
    static let f7: UInt16 = 0x62
    static let f3: UInt16 = 0x63
    static let f8: UInt16 = 0x64
    static let f9: UInt16 = 0x65
    static let f10: UInt16 = 0x6D
    static let f11: UInt16 = 0x67
    static let f12: UInt16 = 0x6F
    static let f13: UInt16 = 0x69
    static let f14: UInt16 = 0x6B
    static let f15: UInt16 = 0x71
    static let f16: UInt16 = 0x6A
    static let f17: UInt16 = 0x40
    static let f18: UInt16 = 0x4F
    static let f19: UInt16 = 0x50
    static let f20: UInt16 = 0x5A
    
    // US-ANSI Keyboard Positions
    // eg. These key codes are for the physical key (in any keyboard layout)
    // at the location of the named key in the US-ANSI layout.
    static let a: UInt16 = 0x00
    static let b: UInt16 = 0x0B
    static let c: UInt16 = 0x08
    static let d: UInt16 = 0x02
    static let e: UInt16 = 0x0E
    static let f: UInt16 = 0x03
    static let g: UInt16 = 0x05
    static let h: UInt16 = 0x04
    static let i: UInt16 = 0x22
    static let j: UInt16 = 0x26
    static let k: UInt16 = 0x28
    static let l: UInt16 = 0x25
    static let m: UInt16 = 0x2E
    static let n: UInt16 = 0x2D
    static let o: UInt16 = 0x1F
    static let p: UInt16 = 0x23
    static let q: UInt16 = 0x0C
    static let r: UInt16 = 0x0F
    static let s: UInt16 = 0x01
    static let t: UInt16 = 0x11
    static let u: UInt16 = 0x20
    static let v: UInt16 = 0x09
    static let w: UInt16 = 0x0D
    static let x: UInt16 = 0x07
    static let y: UInt16 = 0x10
    static let z: UInt16 = 0x06

    static let zero: UInt16 = 0x1D
    static let one: UInt16 = 0x12
    static let two: UInt16 = 0x13
    static let three: UInt16 = 0x14
    static let four: UInt16 = 0x15
    static let five: UInt16 = 0x17
    static let six: UInt16 = 0x16
    static let seven: UInt16 = 0x1A
    static let eight: UInt16 = 0x1C
    static let nine: UInt16 = 0x19
    
    static let equals: UInt16 = 0x18
    static let minus: UInt16 = 0x1B
    static let semicolon: UInt16 = 0x29
    static let apostrophe: UInt16 = 0x27
    static let comma: UInt16 = 0x2B
    static let period: UInt16 = 0x2F
    static let forwardSlash: UInt16 = 0x2C
    static let backslash: UInt16 = 0x2A
    static let grave: UInt16 = 0x32
    static let leftBracket: UInt16 = 0x21
    static let rightBracket: UInt16 = 0x1E
    
    static let keypadDecimal: UInt16 = 0x41
    static let keypadMultiply: UInt16 = 0x43
    static let keypadPlus: UInt16 = 0x45
    static let keypadClear: UInt16 = 0x47
    static let keypadDivide: UInt16 = 0x4B
    static let keypadEnter: UInt16 = 0x4C
    static let keypadMinus: UInt16 = 0x4E
    static let keypadEquals: UInt16 = 0x51
    static let keypad0: UInt16 = 0x52
    static let keypad1: UInt16 = 0x53
    static let keypad2: UInt16 = 0x54
    static let keypad3: UInt16 = 0x55
    static let keypad4: UInt16 = 0x56
    static let keypad5: UInt16 = 0x57
    static let keypad6: UInt16 = 0x58
    static let keypad7: UInt16 = 0x59
    static let keypad8: UInt16 = 0x5B
    static let keypad9: UInt16 = 0x5C
}

enum HTTPStatusCode: Int {
    case none = 0
    // 100 Informational
    case `continue` = 100
    case switchingProtocols
    case processing
    // 200 Success
    case ok = 200
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case iMUsed = 226
    // 300 Redirection
    case multipleChoices = 300
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect
    // 400 Client Error
    case badRequest = 400
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case payloadTooLarge
    case uriTooLong
    case unsupportedMediaType
    case rangeNotSatisfiable
    case expectationFailed
    case imATeapot
    case misdirectedRequest = 421
    case unprocessableEntity
    case locked
    case failedDependency
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    case clientClosedRequest = 499 // nginx non-standard
    // 500 Server Error
    case internalServerError = 500
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended = 510
    case networkAuthenticationRequired
}

extension NSAttributedString {
	
	var attributedStringToRtfString: String {
		var ret = ""
		do {
			let data = try self.data(from: NSRange( location: 0, length: self.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			if let dataString = String.init(data: data, encoding: String.Encoding.utf8) {
				ret = dataString
			}
		} catch {}
		return ret
	}
	
    var attributedString2Html: String? {
        do {
            let htmlData = try self.data(from: NSRange( location: 0, length: self.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
            return String.init(data: htmlData, encoding: String.Encoding.utf8)
        } catch {
            print("error:", error)
            return nil
        }
    }
}

extension BWFont {
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

extension CGPoint {
     init(fromString: String) {
        var cleanStr = fromString.replacingOccurrences(of: "NSPoint: {", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "}", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: " ", with: "")
        let components = cleanStr.components(separatedBy: ",")
        if components.count > 0, let x = Double(components[0]), let y = Double(components[1]) {
            self.init(x: x, y: y)
        } else {
            self.init()
        }
    }
}

extension CGRect {
     init(fromString: String) {
        var cleanStr = fromString.replacingOccurrences(of: "NSRect", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: ":", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "{", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "}", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: " ", with: "")
        let components = cleanStr.components(separatedBy: ",")
        if components.count > 3, let x = Double(components[0]), let y = Double(components[1]), let width = Double(components[2]), let height = Double(components[3]) {
            self.init(x: x, y: y, width: width, height: height)
        } else {
            self.init()
        }
    }
}

extension CGSize {
     init(fromString: String) {
        var cleanStr = fromString.replacingOccurrences(of: "NSSize: {", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "}", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: " ", with: "")
        let components = cleanStr.components(separatedBy: ",")
        if components.count > 0, let width = Double(components[0]), let height = Double(components[1]) {
            self.init(width: width, height: height)
        } else {
            self.init()
        }
    }
}

extension WKWebView {
    func loadWithCookies(_ urlRequest: URLRequest) {
        setSharedCookies()
        self.load(urlRequest)
    }
    
    func setSharedCookies() {
        for (cookie) in BitweaverUser.active.cookieArray {
            #if os(iOS)
                self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            #else
            if #available(OSX 10.13, *) {
                self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            } else {
                // Fallback on earlier versions
            }
            #endif
        }
    }
}
