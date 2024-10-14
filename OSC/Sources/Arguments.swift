//
//  Arguments.swift
//
//
//  Created by kotan.kn on 8/18/R6.
//
import protocol Foundation.MutableDataProtocol
import struct Foundation.Data
import Synchronization
public protocol Argument: Sendable {
	init?(from osc: inout (tags: Substring, body: some MutableDataProtocol))
	func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol))
}
public typealias Arguments = Array<Argument>
extension Arguments {
	@usableFromInline
	static let Entries: Mutex<Array<Argument.Type>> = .init([
		// standards
		Int32.self,
		Float32.self,
		String.self,
		Data.self,
		// alternative
		Int64.self,
		Float64.self,
		Character.self,
		TimeTag.self,
		// special
		Arguments.self,
		Bool.self,
		OSC.Nil.self
	])
	@inlinable
	static func Decode(from osc: inout (tags: Substring, body: some MutableDataProtocol)) -> Optional<Argument> {
		Entries.withLock {
			$0.reduce(.none) {
				$0 ?? $1.init(from: &osc)
			}
		}
	}
	@inlinable
	public static func Register(type: Argument.Type) {
		Entries.withLock {
			$0.append(type)
		}
	}
}
extension Arguments: @retroactive RawRepresentable {
	@inlinable
	public init?(rawValue data: Data) {
		let head = data.prefix { $0 != .zero }
		guard let tags = String(data: head, encoding: .ascii).map(Substring.init(_:)), case.some(",") = tags.first else { return nil }
		self.init(sequence(state: (tags.dropFirst(), data.trimmingPrefix(head).dropFirst(4 - head.count % 4)), next: Self.Decode(from:)))
	}
	@inlinable
	public var rawValue: Data {
		var osc = (tags: "," as Substring, body: Data())
		forEach {
			$0.encode(into: &osc)
		}
		var raw = Data()
		osc.tags.withUTF8 {
			raw.append(contentsOf: $0)
		}
		raw.append(contentsOf: repeatElement(0, count: 4 - osc.tags.count % 4))
		raw.append(contentsOf: osc.body)
		raw.append(contentsOf: repeatElement(0, count: 3 - ( osc.body.count + 3 ) % 4))
		return raw
	}
}
extension Int32: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("i") = osc.tags.first, let value = osc.body.popElement().map(UInt32.init(bigEndian:)) else { return nil }
		self = .init(bitPattern: value)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("i")
		withUnsafeBytes(of: bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension Float32: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("f") = osc.tags.first, let value = osc.body.popElement().map(UInt32.init(bigEndian:)) else { return nil }
		self = .init(bitPattern: value)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("f")
		withUnsafeBytes(of: bitPattern.bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension String: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("s") = osc.tags.first, let value = osc.body.popCString() else { return nil }
		self = value
		osc.body.removeFirst(4 - value.count % 4)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("s")
		var value = prefix { $0 != "\0" }
		value.withUTF8 {
			osc.body.append(contentsOf: $0)
		}
		osc.body.append(contentsOf: repeatElement(0, count: 4 - value.count % 4))
	}
}
extension Data: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("b") = osc.tags.first, let count = osc.body.popElement().map(UInt32.init(bigEndian:)).map(Int.init) else { return nil }
		self = .init(osc.body.pop(count: count))
		osc.body.removeFirst(3 - (count + 3) % 4)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("b")
		Swift.withUnsafeBytes(of: UInt32(count).bigEndian) {
			osc.body.append(contentsOf: $0)
		}
		osc.body.append(contentsOf: self)
		osc.body.append(contentsOf: repeatElement(0, count: 3 - (count + 3) % 4))
	}
}
extension Int64: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("h") = osc.tags.first, let value = osc.body.popElement().map(UInt64.init(bigEndian:)) else { return nil }
		self = .init(bitPattern: value)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("h")
		withUnsafeBytes(of: bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension Float64: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("d") = osc.tags.first, let value = osc.body.popElement().map(UInt64.init(bigEndian:)) else { return nil }
		self = .init(bitPattern: value)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("d")
		withUnsafeBytes(of: bitPattern.bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension Character: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("c") = osc.tags.first, let value = osc.body.popElement().map(UInt32.init(bigEndian:)).flatMap(Unicode.Scalar.init).flatMap(Character.init) else { return nil }
		self = value
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("c")
		withUnsafeBytes(of: UInt32(unicodeScalars.first.unsafelyUnwrapped).bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension TimeTag: Argument {
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("t") = osc.tags.first, let value = osc.body.popElement().map(UInt64.init(bigEndian:)) else { return nil }
		self = .init(rawValue: value)
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("t")
		withUnsafeBytes(of: rawValue.bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
extension Arguments: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("[") = osc.tags.first else { return nil }
		osc.tags.removeFirst()
		self.init()
		repeat {
			switch osc.tags.first {
			case.some("]"):
				osc.tags.removeFirst()
				return
			case.some:
				switch Self.Decode(from: &osc) {
				case.some(let element):
					append(element)
				case.none:
					return nil
				}
			case.none:
				return nil
			}
		} while true
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("[")
		forEach {
			$0.encode(into: &osc)
		}
		osc.tags.append("]")
	}
}
extension Bool: Argument {
	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		switch osc.tags.first {
		case.some("T"):
			osc.tags.removeFirst()
			self = true
		case.some("F"):
			osc.tags.removeFirst()
			self = false
		case.some, .none:
			return nil
		}
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append(self ? "T" : "F")
	}
}
struct Nil {}
extension Nil: Argument {
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("N") = osc.tags.first else { return nil }
		osc.tags.removeFirst()
	}
	@inlinable
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("N")
	}
}
struct Impulse {}
extension Impulse: Argument {
//	@inlinable
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("I") = osc.tags.first else { return nil }
		osc.tags.removeFirst()
	}
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("I")
	}
}
extension Arguments {
	public static let Nil: some Argument = OSC.Nil()
	public static let Impulse: some Argument = OSC.Impulse()
}
