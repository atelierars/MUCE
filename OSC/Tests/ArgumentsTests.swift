import XCTest
import Foundation
import CoreMIDI
extension MIDIMessage_32: Argument {
	public init?(from osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		guard case.some("m") = osc.tags.first, let value = osc.body.popElement().map(UInt32.init(bigEndian:)) else { return nil }
		self = value
	}
	public func encode(into osc: inout (tags: Substring, body: some MutableDataProtocol)) {
		osc.tags.append("m")
		withUnsafeBytes(of: bigEndian) {
			osc.body.append(contentsOf: $0)
		}
	}
}
@testable import OSC
final class ArgumentsTests: XCTestCase {
	func scenario<T: Argument & Equatable>(raw: T) {
		var osc = (tags: "" as Substring, body: Data())
		raw.encode(into: &osc)
		XCTAssertEqual(T.init(from: &osc), .some(raw))
	}
	func testI32() {
		scenario(raw: Int32.random(in: Int32.min...Int32.max))
	}
	func testF32() {
		scenario(raw: Float32.random(in: -1...1))
	}
	func testText() {
		scenario(raw: "something")
	}
	func testBlob() {
		scenario(raw: Data(Array(repeating: (), count: .random(in: 32...64)).map { UInt8.random(in: UInt8.min...UInt8.max) }))
	}
	func testI64() {
		scenario(raw: Int64.random(in: Int64.min...Int64.max))
	}
	func testF64() {
		scenario(raw: Float64.random(in: -1...1))
	}
	func testChar() {
		scenario(raw: "" as Character)
	}
	func testArgs() {
		var osc = (tags: "" as Substring, body: Data())
		let raw = [
			Bool.random(),
			Data(repeatElement((), count: .random(in: 32...64)).map { UInt8.random(in: UInt8.min...UInt8.max) }),
			Int32.random(in: Int32.min...Int32.max),
			Int64.random(in: Int64.min...Int64.max),
			"hello world",
			Float32.random(in: -1...1),
			Float64.random(in: -1...1),
		] as Arguments
		raw.encode(into: &osc)
		guard let dec = Arguments(from: &osc) else {
			XCTFail()
			return
		}
		zip(raw, dec).forEach {
			switch ($0, $1) {
			case let (x, y) as (Int32, Int32):
				XCTAssertEqual(x, y)
			case let (x, y) as (Float32, Float32):
				XCTAssertEqual(x, y)
			case let (x, y) as (Int64, Int64):
				XCTAssertEqual(x, y)
			case let (x, y) as (Float64, Float64):
				XCTAssertEqual(x, y)
			case let (x, y) as (Bool, Bool):
				XCTAssertEqual(x, y)
			case let (x, y) as (String, String):
				XCTAssertEqual(x, y)
			case let (x, y) as (Data, Data):
				XCTAssertEqual(x, y)
			default:
				XCTFail("\($0) vs \($1)")
			}
		}
	}
	func testBool() {
		scenario(raw: Bool.random())
	}
	func testRawData() {
		let raw = [
			"",
			Int32.random(in: Int32.min...Int32.max),
			"1",
			Float64.random(in: -1...1),
			"22",
			Bool.random(),
			"333",
			Int64.random(in: Int64.min...Int64.max),
			"4444",
			Float64.random(in: -1...1)
		] as Arguments
		let enc = raw.rawValue
		guard let dec = Arguments(rawValue: enc) else {
			XCTFail()
			return
		}
		zip(raw, dec).forEach {
			switch ($0, $1) {
			case let (x, y) as (Int32, Int32):
				XCTAssertEqual(x, y)
			case let (x, y) as (Float32, Float32):
				XCTAssertEqual(x, y)
			case let (x, y) as (Int64, Int64):
				XCTAssertEqual(x, y)
			case let (x, y) as (Float64, Float64):
				XCTAssertEqual(x, y)
			case let (x, y) as (Bool, Bool):
				XCTAssertEqual(x, y)
			case let (x, y) as (String, String):
				XCTAssertEqual(x, y)
			default:
				XCTFail("\($0) vs \($1)")
			}
		}
	}
	func testCustomArgType() {
		Arguments.Register(type: MIDIMessage_32.self)
		let raw = [
			MIDIMessage_32(bigEndian: 0x01020304)
		] as Arguments
		let enc = raw.rawValue
		guard let dec = Arguments(rawValue: enc) else {
			XCTFail()
			return
		}
		XCTAssertEqual(dec.first as?MIDIMessage_32, raw.first as?MIDIMessage_32)
	}
}
