import Testing
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
@Suite
struct ArgumentTests {
	func scenario<T: Argument & Equatable>(raw: T) {
		var osc = (tags: "" as Substring, body: Data())
		raw.encode(into: &osc)
		#expect(T.init(from: &osc) == .some(raw))
	}
	@Test(arguments: Array<ClosedRange<Int32>>(repeating: Int32.min...Int32.max, count: 16).map(Int32.random(in:)))
	func testI32(argument value: Int32) {
		scenario(raw: value)
	}
	@Test(arguments: Array<ClosedRange<Float32>>(repeating: -1...1, count: 16).map(Float32.random(in:)))
	func testF32(argument value: Float32) {
		scenario(raw: value)
	}
	@Test
	func text() {
		scenario(raw: "something")
	}
	@Test
	func blob() {
		scenario(raw: Data(Array(repeating: (), count: .random(in: 32...64)).map { UInt8.random(in: UInt8.min...UInt8.max) }))
	}
	@Test(arguments: Array<ClosedRange<Int64>>(repeating: Int64.min...Int64.max, count: 16).map(Int64.random(in:)))
	func i64(val: Int64) {
		scenario(raw: val)
	}
	@Test(arguments: Array<ClosedRange<Float64>>(repeating: -1...1, count: 16).map(Float64.random(in:)))
	func f64(val: Float64) {
		scenario(raw: val)
	}
	@Test
	func char() {
		scenario(raw: "" as Character)
	}
	@Test
	func args() {
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
			Issue.record()
			return
		}
		zip(raw, dec).forEach {
			switch ($0, $1) {
			case let (x, y) as (Int32, Int32):
				#expect(x == y)
			case let (x, y) as (Float32, Float32):
				#expect(x == y)
			case let (x, y) as (Int64, Int64):
				#expect(x == y)
			case let (x, y) as (Float64, Float64):
				#expect(x == y)
			case let (x, y) as (Bool, Bool):
				#expect(x == y)
			case let (x, y) as (String, String):
				#expect(x == y)
			case let (x, y) as (Data, Data):
				#expect(x == y)
			default:
				Issue.record("\($0) vs \($1)")
			}
		}
	}
	@Test(arguments: [false, true])
	func bool(val: Bool) {
		scenario(raw: val)
	}
	@Test
	func data() {
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
			Issue.record()
			return
		}
		zip(raw, dec).forEach {
			switch ($0, $1) {
			case let (x, y) as (Int32, Int32):
				#expect(x == y)
			case let (x, y) as (Float32, Float32):
				#expect(x == y)
			case let (x, y) as (Int64, Int64):
				#expect(x == y)
			case let (x, y) as (Float64, Float64):
				#expect(x == y)
			case let (x, y) as (Bool, Bool):
				#expect(x == y)
			case let (x, y) as (String, String):
				#expect(x == y)
			default:
				Issue.record("\($0) vs \($1)")
			}
		}
	}
	@Test
	func midi() {
		Arguments.Register(type: MIDIMessage_32.self)
		let raw = [
			MIDIMessage_32(bigEndian: 0x01020304)
		] as Arguments
		let enc = raw.rawValue
		guard let dec = Arguments(rawValue: enc), let lhs = raw.first as?MIDIMessage_32, let rhs = dec.first as?MIDIMessage_32 else {
			Issue.record()
			return
		}
		#expect(lhs == rhs)
	}
}
