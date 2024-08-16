//
//  Argument.swift
//  
//
//  Created by kotan.kn on 8/5/R6.
//
import protocol Foundation.MutableDataProtocol
import protocol Foundation.DataProtocol
import struct Foundation.Data
import os.log
public enum Argument {
	// standard
	case i32(Int32)
	case f32(Float32)
	case text(String)
	case blob(Data)
	// alternative
	case i64(Int64)
	case f64(Float64)
	case char(Character)
	case time(TimeTag)
	// special
	case array(Array<Argument>)
	case bool(Bool)
	case`nil`
}
extension Argument: ExpressibleByIntegerLiteral {
	@inlinable
	public init(integerLiteral value: Int32) {
		self = .i32(value)
	}
}
extension Argument: ExpressibleByFloatLiteral {
	public init(floatLiteral value: Float32) {
		self = .f32(value)
	}
}
extension Argument: ExpressibleByStringLiteral {
	@inlinable
	public init(stringLiteral value: String) {
		self = .text(value)
	}
}
extension Argument: ExpressibleByUnicodeScalarLiteral {
	public init(unicodeScalarLiteral value: Character) {
		self = .char(value)
	}
}
extension Argument: ExpressibleByArrayLiteral {
	@inlinable
	public init(arrayLiteral elements: Argument...) {
		self = .array(elements)
	}
}
extension Argument: ExpressibleByBooleanLiteral {
	@inlinable
	public init(booleanLiteral value: BooleanLiteralType) {
		self = .bool(value)
	}
}
extension Argument: ExpressibleByNilLiteral {
	@inlinable
	public init(nilLiteral: ()) {
		self = .nil
	}
}
extension Argument {
	// standards
	@inlinable
	public init(_ value: Int32) {
		self = .i32(value)
	}
	@inlinable
	public init(_ value: Float32) {
		self = .f32(value)
	}
	@inlinable
	public init(_ value: String) {
		self = .text(value)
	}
	@inlinable
	public init(_ value: Data) {
		self = .blob(value)
	}
	// alternative
	@inlinable
	public init(_ value: Int64) {
		self = .i64(value)
	}
	@inlinable
	public init(_ value: Float64) {
		self = .f64(value)
	}
	@inlinable
	public init(_ value: Character) {
		self = .char(value)
	}
	@inlinable
	public init(_ value: TimeTag) {
		self = .time(value)
	}
	// special
	@inlinable
	public init(_ value: Bool) {
		self = .bool(value)
	}
	@inlinable
	public init(_ value: ()) {
		self = .nil
	}
}
extension Argument {
	@inlinable
	public var isStandard: Bool {
		switch self {
		case.i32,.f32,.text,.blob:
			true
		default:
			false
		}
	}
}
extension Argument: Equatable {
	
}
extension Argument: CustomStringConvertible {
	@inlinable
	public var description: String {
		switch self {
		case.i32(let value):
			"\(value)"
		case.f32(let value):
			"\(value)"
		case.text(let value):
			"\"\(value)\""
		case.blob(let value):
			"\(value)"
		case.i64(let value):
			"\(value)"
		case.f64(let value):
			"\(value)"
		case.char(let value):
			"\(value)"
		case.time(let value):
			"\(value)"
		case.array(let value):
			"\(value)"
		case.bool(let value):
			"\(value)"
		case.nil:
			"\(())"
		}
	}
}
extension Argument {
	@inlinable
	public var i32: Optional<Int32> {
		switch self {
		case.i32(let value):
			.some(value)
		default:
			.none
		}
	}
	@inlinable
	public var i64: Optional<Int64> {
		switch self {
		case.i64(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var f32: Optional<Float32> {
		switch self {
		case.f32(let value):
			.some(value)
		default:
			.none
		}
	}
	@inlinable
	public var f64: Optional<Float64> {
		switch self {
		case.f64(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var text: Optional<String> {
		switch self {
		case.text(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var blob: Optional<Data> {
		switch self {
		case.blob(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var time: Optional<TimeTag> {
		switch self {
		case.time(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var bool: Optional<Bool> {
		switch self {
		case.bool(let value):
			.some(value)
		default:
			.none
		}
	}
}
extension Argument {
	@inlinable
	public var`nil`: Optional<()> {
		switch self {
		case.nil:
			.some(())
		default:
			.none
		}
	}
}
extension Argument: RawRepresentable {
	@inlinable
	public init?(rawValue: Any) {
		switch rawValue {
		case let value as Int32:
			self = .i32(value)
		case let value as Float32:
			self = .f32(value)
		case let value as String:
			self = .text(value)
		case let value as Data:
			self = .blob(value)
		case let value as Int64:
			self = .i64(value)
		case let value as Float64:
			self = .f64(value)
		case let value as Character:
			self = .char(value)
		case let value as TimeTag:
			self = .time(value)
		case let value as Array<Argument>:
			self = .array(value)
		case let value as Bool:
			self = .bool(value)
		case is ():
			self = .nil
		default:
			return nil
		}
	}
	@inlinable
	public var rawValue: Any {
		switch self {
		case.i32(let value):
			value
		case.f32(let value):
			value
		case.text(let value):
			value
		case.blob(let value):
			value
		case.i64(let value):
			value
		case.f64(let value):
			value
		case.char(let value):
			value
		case.time(let value):
			value
		case.array(let value):
			value
		case.bool(let value):
			value
		case.nil:
			()
		}
	}
}
extension Argument {
	init?<T: MutableDataProtocol>(decode tags: inout T, with data: inout some MutableDataProtocol) where T.SubSequence == T {
		switch tags.popFirst().map(Unicode.Scalar.init).map(Character.init) ?? "\0" {
		case "i":
			guard let value = data.popElement().map(UInt32.init(bigEndian:)) else { return nil }
			self = .i32(.init(bitPattern: value))
		case "f":
			guard let value = data.popElement().map(UInt32.init(bigEndian:)) else { return nil }
			self = .f32(.init(bitPattern: value))
		case "s":
			guard let value = data.popCString() else { return nil } // without EOF
			self = .text(value)
			data.pop(count: 4 - ( value.count + 4 ) % 4)
		case "b":
			guard let count = data.popElement().map(UInt32.init(bigEndian:)) else { return nil }
			let value = data.pop(count: .init(count))
			self = .blob(.init(value))
			data.pop(count: 3 - ( value.count + 3 ) % 4)
		case "h":
			guard let value = data.popElement().map(UInt64.init(bigEndian:)) else { return nil }
			self = .i64(.init(bitPattern: value))
		case "d":
			guard let value = data.popElement().map(UInt64.init(bigEndian:)) else { return nil }
			self = .f64(.init(bitPattern: value))
		case "c":
			guard let value = data.popElement().map(UInt32.init(bigEndian:)) else { return nil }
			self = .char(.init(.init(value).unsafelyUnwrapped))
		case "t":
			guard let value = data.popElement().map(UInt64.init(bigEndian:)) else { return nil }
			self = .time(.init(rawValue: value))
		case "[":
			var array = Array<Self>()
			while let value = tags.first.map(Unicode.Scalar.init).map(Character.init) {
				switch value {
				case "]":
					self = .array(array)
					tags.removeFirst()
					return
				default:
					guard let value = Self(decode: &tags, with: &data) else { return nil }
					array.append(value)
				}
			}
			return nil
		case "T":
			self = true
		case "F":
			self = false
		case "N":
			self = nil
		case let tag:
			assertionFailure("\(tag) is not implemented")
			os_log(.debug, "%s is not supported", String(tag))
			return nil
		}
	}
}
extension Argument {
	func encode(into tags: inout some MutableDataProtocol, with data: inout some MutableDataProtocol) {
		switch self {
		case.i32(let value):
			tags.append(("i" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: value.bigEndian) {
				data.append(contentsOf: $0)
			}
		case.f32(let value):
			tags.append(("f" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: value.bitPattern.bigEndian) {
				data.append(contentsOf: $0)
			}
		case.text(let value): // UTF8 is also available
			let value = value.replacingOccurrences(of: "\0", with: "").data(using: .utf8) ?? .init()
			tags.append(("s" as Character).asciiValue.unsafelyUnwrapped)
			data.append(contentsOf: value)
			data.append(contentsOf: Data(count: 4 - (value.count + 4) % 4))
		case.blob(let value):
			let value = value.prefix(.init(UInt32.max))
			tags.append(("b" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: UInt32(value.count).bigEndian) { data.append(contentsOf: $0) }
			data.append(contentsOf: value)
			data.append(contentsOf: Data(count: 3 - (value.count + 3) % 4))
		case.i64(let value):
			tags.append(("h" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: value.bigEndian) {
				data.append(contentsOf: $0)
			}
		case.f64(let value):
			tags.append(("d" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: value.bitPattern.bigEndian) {
				data.append(contentsOf: $0)
			}
		case.char(let value):
			tags.append(("c" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: UInt32(value.unicodeScalars.first.unsafelyUnwrapped).bigEndian) {
				data.append(contentsOf: $0)
			}
		case.time(let value):
			tags.append(("t" as Character).asciiValue.unsafelyUnwrapped)
			withUnsafeBytes(of: value.rawValue.bigEndian) {
				data.append(contentsOf: $0)
			}
		case.array(let value):
			tags.append(("[" as Character).asciiValue.unsafelyUnwrapped)
			value.forEach {
				$0.encode(into: &tags, with: &data)
			}
			tags.append(("]" as Character).asciiValue.unsafelyUnwrapped)
		case.bool(true):
			tags.append(("T" as Character).asciiValue.unsafelyUnwrapped)
		case.bool(false):
			tags.append(("F" as Character).asciiValue.unsafelyUnwrapped)
		case.nil:
			tags.append(("N" as Character).asciiValue.unsafelyUnwrapped)
		}
	}
}
