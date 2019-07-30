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
#else
import Cocoa

typealias BWImage = NSImage
typealias BWView = NSView
typealias BWViewController = NSViewController
typealias BWColor = NSColor
#endif

extension BWViewController {
    func dialogOKCancel(question: String, text: String) -> Bool {
        #if os(iOS)
        #elseif os(macOS)
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
        #endif
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
}

extension Data {
	func digest() -> String {
		let hexDigest = self.map { String(format: "%02hhx", $0) }.joined()
		return hexDigest
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

extension BWView {
    func clearChildren() {
        subviews.forEach({
            $0.removeFromSuperview()
        })
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
            BitweaverAppBase.log("failed to write to disk. url: %@", url.absoluteString)
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

extension CGImage {
    func saveAsJPG(url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeJPEG, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, self, nil)
        return CGImageDestinationFinalize(destination)
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

//LRU Cache system https://github.com/raywenderlich/swift-algorithm-club/tree/master/LRU%20Cache
public class LRUCache<KeyType: Hashable> {
	private let maxSize: Int
	private var cache: [KeyType: NSImage] = [:]
	private var priority: LinkedList<KeyType> = LinkedList<KeyType>()
	private var key2node: [KeyType: LinkedList<KeyType>.LinkedListNode<KeyType>] = [:]
	
	public init(_ maxSize: Int) {
		self.maxSize = maxSize
	}
	
	public func get(_ key: KeyType) -> NSImage? {
		guard let val = cache[key] else {
			return nil
		}
		
		remove(key)
		insert(key, val: val)
		
		return val
	}
	
	public func set(_ key: KeyType, val: NSImage) {
		if cache[key] != nil {
			remove(key)
		} else if priority.count >= maxSize, let keyToRemove = priority.last?.value {
			remove(keyToRemove)
		}
		
		insert(key, val: val)
	}
	
	private func remove(_ key: KeyType) {
		cache.removeValue(forKey: key)
		guard let node = key2node[key] else {
			return
		}
		priority.remove(node: node)
		key2node.removeValue(forKey: key)
	}
	
	private func insert(_ key: KeyType, val: NSImage) {
		cache[key] = val
		priority.insert(key, atIndex: 0)
		guard let first = priority.first else {
			return
		}
		key2node[key] = first
	}
}

public final class LinkedList<T> {
	
	public class LinkedListNode<T> {
		var value: T
		var next: LinkedListNode?
		weak var previous: LinkedListNode?
		
		public init(value: T) {
			self.value = value
		}
	}
	
	public typealias Node = LinkedListNode<T>
	
	fileprivate var head: Node?
	
	public init() {}
	
	public var isEmpty: Bool {
		return head == nil
	}
	
	public var first: Node? {
		return head
	}
	
	public var last: Node? {
		if var node = head {
			while let next = node.next {
				node = next
			}
			return node
		} else {
			return nil
		}
	}
	
	public var count: Int {
		if var node = head {
			var c = 1
			while let next = node.next {
				node = next
				c += 1
			}
			return c
		} else {
			return 0
		}
	}
	
	public func node(atIndex index: Int) -> Node? {
		if index >= 0 {
			var node = head
			var i = index
			while node != nil {
				if i == 0 { return node }
				i -= 1
				node = node!.next
			}
		}
		return nil
	}
	
	public subscript(index: Int) -> T {
		let node = self.node(atIndex: index)
		assert(node != nil)
		return node!.value
	}
	
	public func append(_ value: T) {
		let newNode = Node(value: value)
		self.append(newNode)
	}
	
	public func append(_ node: Node) {
		let newNode = LinkedListNode(value: node.value)
		if let lastNode = last {
			newNode.previous = lastNode
			lastNode.next = newNode
		} else {
			head = newNode
		}
	}
	
	public func append(_ list: LinkedList) {
		var nodeToCopy = list.head
		while let node = nodeToCopy {
			self.append(node.value)
			nodeToCopy = node.next
		}
	}
	
	private func nodesBeforeAndAfter(index: Int) -> (Node?, Node?) {
		assert(index >= 0)
		
		var i = index
		var next = head
		var prev: Node?
		
		while next != nil && i > 0 {
			i -= 1
			prev = next
			next = next!.next
		}
		assert(i == 0)  // if > 0, then specified index was too large
		return (prev, next)
	}
	
	public func insert(_ value: T, atIndex index: Int) {
		let newNode = Node(value: value)
		self.insert(newNode, atIndex: index)
	}
	
	public func insert(_ node: Node, atIndex index: Int) {
		let (prev, next) = nodesBeforeAndAfter(index: index)
		let newNode = LinkedListNode(value: node.value)
		newNode.previous = prev
		newNode.next = next
		prev?.next = newNode
		next?.previous = newNode
		
		if prev == nil {
			head = newNode
		}
	}
	
	public func insert(_ list: LinkedList, atIndex index: Int) {
		if list.isEmpty { return }
		var (prev, next) = nodesBeforeAndAfter(index: index)
		var nodeToCopy = list.head
		var newNode: Node?
		while let node = nodeToCopy {
			newNode = Node(value: node.value)
			newNode?.previous = prev
			if let previous = prev {
				previous.next = newNode
			} else {
				self.head = newNode
			}
			nodeToCopy = nodeToCopy?.next
			prev = newNode
		}
		prev?.next = next
		next?.previous = prev
	}
	
	public func removeAll() {
		head = nil
	}
	
	@discardableResult public func remove(node: Node) -> T {
		let prev = node.previous
		let next = node.next
		
		if let prev = prev {
			prev.next = next
		} else {
			head = next
		}
		next?.previous = prev
		
		node.previous = nil
		node.next = nil
		return node.value
	}
	
	@discardableResult public func removeLast() -> T {
		assert(!isEmpty)
		return remove(node: last!)
	}
	
	@discardableResult public func remove(atIndex index: Int) -> T {
		let node = self.node(atIndex: index)
		assert(node != nil)
		return remove(node: node!)
	}
}

extension LinkedList: CustomStringConvertible {
	public var description: String {
		var s = "["
		var node = head
		while node != nil {
			s += "\(node!.value)"
			node = node!.next
			if node != nil { s += ", " }
		}
		return s + "]"
	}
}

extension LinkedList {
	public func reverse() {
		var node = head
		while let currentNode = node {
			node = currentNode.next
			swap(&currentNode.next, &currentNode.previous)
			head = currentNode
		}
	}
}

extension LinkedList {
	public func map<U>(transform: (T) -> U) -> LinkedList<U> {
		let result = LinkedList<U>()
		var node = head
		while node != nil {
			result.append(transform(node!.value))
			node = node!.next
		}
		return result
	}
	
	public func filter(predicate: (T) -> Bool) -> LinkedList<T> {
		let result = LinkedList<T>()
		var node = head
		while node != nil {
			if predicate(node!.value) {
				result.append(node!.value)
			}
			node = node!.next
		}
		return result
	}
}

extension LinkedList {
	convenience init(array: Array<T>) {
		self.init()
		
		for element in array {
			self.append(element)
		}
	}
}

extension LinkedList: ExpressibleByArrayLiteral {
	public convenience init(arrayLiteral elements: T...) {
		self.init()
		
		for element in elements {
			self.append(element)
		}
	}
}
