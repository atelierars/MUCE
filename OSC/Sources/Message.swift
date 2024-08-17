//
//  Message.swift
//
//
//  Created by Kota on 8/17/R6.
//
import protocol Foundation.DataProtocol
import struct Foundation.Data
import RegexBuilder
@frozen public struct Message {
	public let address: String
	@usableFromInline
	var arguments: Array<Argument>
	public init(_ address: some StringProtocol, with arguments: some Sequence<Argument> = []) {
		self.address = address.replacingOccurrences(of: "\0", with: "")
		self.arguments = .init(arguments)
	}
}
extension Message: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.init(value)
	}
}
extension Message {
	// standard
	@inlinable
	public mutating func append(_ value: Int32) {
		arguments.append(.i32(value))
	}
	@inlinable
	public mutating func append(_ value: Float32) {
		arguments.append(.f32(value))
	}
	@inlinable
	public mutating func append(_ value: some StringProtocol) {
		arguments.append(.text(.init(value)))
	}
	@inlinable
	public mutating func append(_ value: some DataProtocol) {
		arguments.append(.blob(.init(value)))
	}
	// alternative
	@inlinable
	public mutating func append(_ value: Int64) {
		arguments.append(.i64(value))
	}
	@inlinable
	public mutating func append(_ value: Float64) {
		arguments.append(.f64(value))
	}
	@inlinable
	public mutating func append(_ value: Character) {
		arguments.append(.char(value))
	}
	@inlinable
	public mutating func append(_ value: TimeTag) {
		arguments.append(.time(value))
	}
	// special
	@inlinable
	public mutating func append(_ value: some Sequence<Argument>) {
		arguments.append(.array(.init(value)))
	}
	@inlinable
	public mutating func append(_ value: Bool) {
		arguments.append(.bool(value))
	}
	@inlinable
	public mutating func append(_ value: ()) {
		arguments.append(.nil)
	}
}
extension Message {
	public var isStandard: Bool {
		address.starts(with: "/") && arguments.allSatisfy { $0.isStandard }
	}
}
extension Message: RandomAccessCollection & MutableCollection {
	@inlinable
	public var startIndex: Array<Argument>.Index { arguments.startIndex }
	@inlinable
	public var endIndex: Array<Argument>.Index { arguments.endIndex }
	@inlinable
	public subscript(position: Int) -> Argument {
		get {
			arguments[position]
		}
		set {
			arguments[position] = newValue
		}
	}
}
extension Message {
	@inlinable
	public static func~=(lhs: String, rhs: Self) -> Bool {
		(try?Regex(glob: rhs.address)).flatMap(lhs.wholeMatch(of:)) != nil
	}
//	public static func~=(lhs: Self, rhs: some StringProtocol) -> Bool {
//		(try?Regex(glob: rhs)).flatMap(lhs.address.wholeMatch(of:)) != nil
//	}
//	public static func~=(lhs: some StringProtocol, rhs: Self) -> Bool {
//		(try?Regex(glob: lhs)).flatMap(rhs.address.wholeMatch(of:)) != nil
//	}
	@inlinable
	public static func~=(lhs: some RegexComponent, rhs: Self) -> Bool {
		rhs.address.wholeMatch(of: lhs) != nil
	}
}
extension Message: Equatable {}
extension Message: CustomStringConvertible {
	@inlinable
	public var description: String {
		"\(address) \(arguments)"
	}
}
