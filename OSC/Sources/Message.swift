//
//  Message.swift
//
//
//  Created by kotan.kn on 8/17/R6.
//
import protocol Foundation.DataProtocol
import struct Foundation.Data
import RegexBuilder
@frozen public struct Message {
	public let address: String
	@usableFromInline
	var arguments: Arguments
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
	@inlinable
	public mutating func append(_ value: some Argument) {
		arguments.append(value)
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
		(try?Regex(osc: rhs.address)).flatMap(lhs.wholeMatch(of:)) != nil
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
extension Message: CustomStringConvertible {
	@inlinable
	public var description: String {
		"\(address) \(arguments)"
	}
}
