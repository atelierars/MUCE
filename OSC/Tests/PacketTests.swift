import XCTest
@testable import OSC
final class PacketTests: XCTestCase {
	func testMessageEmpty() {
		let raw = Packet.Message(address: "/test", arguments: [])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
	func testMessageArg1() {
		let raw = Packet.Message(address: "/test", arguments: [1])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
	func testMessageArg2() {
		let raw = Packet.Message(address: "/test", arguments: [1, 2.0])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
	func testMessageArg3() {
		let raw = Packet.Message(address: "/test", arguments: [1, [2.0], "3"])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
	func testMessage4() {
		let raw = Packet.Message(address: "/test", arguments: [1, [2.0, ["3"]], 4])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
	func testBundle() {
		let raw = Packet.Bundle(at: .init(date: Date.now), packets: [
			.Message(address: "/root/1", arguments: [1, 2.0, "3"]),
			.Bundle(at: .immediately, packets: [
				.Message(address: "/sub/2", arguments: []),
				.Message(address: "/sub/3", arguments: ["sub 3"]),
			]),
			.Message(address: "/root/2", arguments: [1, 2.0, "3"]),
			.Bundle(at: .immediately, packets: [
				.Bundle(at: .immediately, packets: [
					.Message(address: "/sub/sub/1", arguments: [1, [3, [
						"5",
						["120", true],
						[false, Data([1,2,3])],
						nil as Nil
					], 4], 2]),
					.Message(address: "/sub/sub/2", arguments: ["EOF"]),
				]),
			]),
		])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		XCTAssertEqual(dec, .some(raw))
	}
}
