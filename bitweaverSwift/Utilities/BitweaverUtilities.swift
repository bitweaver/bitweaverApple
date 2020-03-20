//
//  BitweaverUtilities.swift
//  PrestoPhoto
//
//  Created by Christian Fowler on 9/27/18.
//  Copyright © 2018 PrestoPhoto. All rights reserved.
//

// App wide alias for iOS and macOS cross platform convenience

#if os(iOS)
import UIKit

typealias BWImage = UIImage
typealias BWView = UIView
typealias BWViewController = UIViewController
typealias BWColor = UIColor
typealias BWFont = UIFont
#else
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
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            return fileAttributes[FileAttributeKey.creationDate] as? Date
        } catch {
            print("error getting creationDate from url " + error.localizedDescription)
        }
        return nil
    }
    
    func lastModifiedDate() -> Date? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: self.path)
            return fileAttributes[FileAttributeKey.modificationDate] as? Date
        } catch {
            print("error getting modificationDate from url " + error.localizedDescription)
        }
        return nil
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
}

extension Data {
	func digest() -> String {
		let hexDigest = self.map { String(format: "%02hhx", $0) }.joined()
		return hexDigest
	}
}

extension Date {
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
	
	var isValidEmail: Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
		let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
		return emailPred.evaluate(with: self)
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
        var checkedHex: String = hexValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if checkedHex.isEmpty {
            checkedHex = "#FFFFFF"
        }
        let scanner = Scanner(string: checkedHex)

        if checkedHex.hasPrefix("#") {
            scanner.scanLocation = 1
        }

        var color: UInt32 = 0
        scanner.scanHexInt32(&color)

        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask

        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1)
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

extension BWColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format: "#%06x", rgb)
    }
}

extension CGPoint {
     init(fromString: String) {
        var cleanStr = fromString.replacingOccurrences(of: "NSPoint: {", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "}", with: "")
        let components = cleanStr.components(separatedBy: ",")
        if components.count > 0, let x = NumberFormatter().number(from: components[0]) as? CGFloat, let y = NumberFormatter().number(from: components[1]) as? CGFloat {
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
        if components.count > 3, let x = NumberFormatter().number(from: components[0]) as? CGFloat, let y = NumberFormatter().number(from: components[1]) as? CGFloat, let width = NumberFormatter().number(from: components[2]) as? CGFloat, let height = NumberFormatter().number(from: components[3]) as? CGFloat {
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
        if components.count > 0, let width = NumberFormatter().number(from: components[0]) as? CGFloat, let height = NumberFormatter().number(from: components[1]) as? CGFloat {
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
extension UIDevice {
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #endif
        }
        return mapToDevice(identifier: identifier)
    }()

}
