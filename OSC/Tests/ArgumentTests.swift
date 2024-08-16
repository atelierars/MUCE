import XCTest
@testable import OSC
final class ArgumentTests: XCTestCase {
	func testAny() {
		XCTAssertEqual(Argument(rawValue: []), .some([]))
		XCTAssertEqual(Argument(rawValue: ()), .some(nil))
		XCTAssertEqual(Argument(rawValue: true), .some(true))
		XCTAssertEqual(Argument(rawValue: false), .some(false))
		XCTAssertNotEqual(Argument(rawValue: ()), .some([]))
		XCTAssertNotEqual(Argument(rawValue: []), .some(nil))
		XCTAssertNotEqual(Argument(rawValue: ()), .some(true))
		XCTAssertNotEqual(Argument(rawValue: ()), .some(false))
	}
	func testI32() {
		let value = Int32.random(in: Int32.min...Int32.max)
		let arg = Argument.i32(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.i32(value)))
	}
	func testF32() {
		let value = Float32.random(in: 0...1)
		let arg = Argument.f32(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.f32(value)))
	}
	func testString() {
		for value in ["", "T", "TE", "TES", "TEST", "FINISH"] {
			let arg = Argument.text(value)
			var head = Data()
			var body = Data()
			arg.encode(into: &head, with: &body)
			let dec = Argument(decode: &head, with: &body)
			XCTAssertEqual(dec, .some(.text(value)), "failed for \(value)")
		}
	}
	func testBlob() {
		for count in 0..<8 {
			let value = Data(Array(repeating: (), count: count).map { UInt8.random(in: 0...255) })
			let arg = .blob(value) as Argument
			var head = Data()
			var body = Data()
			arg.encode(into: &head, with: &body)
			let dec = Argument(decode: &head, with: &body)
			XCTAssertEqual(dec, .some(.blob(value)), "failed for \(count)")
		}
	}
	func testI64() {
		let value = Int64.random(in: Int64.min..<Int64.max)
		let arg = Argument.i64(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.i64(value)))
	}
	func testF64() {
		let value = Float64.random(in: 0...1)
		let arg = Argument.f64(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.f64(value)))
	}
	func testChar() {
		let value = "" as Character
		let arg = Argument.char(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.char(value)))
	}
	func testTime() {
		let value = TimeTag(rawValue: .random(in: UInt64.min...UInt64.max))
		let arg = Argument.time(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.time(value)))
	}
	func testArray() {
		let value = [1, 2.0, "3"] as Array<Argument>
		let arg = Argument.array(value)
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertEqual(dec, .some(.array(value)))
	}
	func testT() {
		let arg = true as Argument
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertTrue(body.isEmpty)
		XCTAssertEqual(dec, .some(.bool(true)))
	}
	func testF() {
		let arg = false as Argument
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertTrue(body.isEmpty)
		XCTAssertEqual(dec, .some(.bool(false)))
	}
	func testNil() {
		let arg = nil as Argument
		var head = Data()
		var body = Data()
		arg.encode(into: &head, with: &body)
		let dec = Argument(decode: &head, with: &body)
		XCTAssertTrue(body.isEmpty)
		XCTAssertEqual(dec, .some(.nil))
	}
}
