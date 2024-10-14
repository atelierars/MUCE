import Testing
import struct Foundation.Data
import struct Foundation.Date
@testable import OSC
@Suite
struct PacketTests {
	@Test
	func empty() {
		let raw = Packet.Message(address: "/test", arguments: [])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
	@Test
	func arg1() {
		let raw = Packet.Message(address: "/test", arguments: [1])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
	@Test
	func arg2() {
		let raw = Packet.Message(address: "/test", arguments: [1, 2.0])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
	@Test
	func arg3() {
		let raw = Packet.Message(address: "/test", arguments: [1, [2.0], "3"])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
	@Test
	func arg4() {
		let raw = Packet.Message(address: "/test", arguments: [1, [2.0, ["3"]], 4])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
	@Test
	func bundle() {
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
						Arguments.Nil
					], 4], 2]),
					.Message(address: "/sub/sub/2", arguments: ["EOF"]),
				]),
			]),
		])
		let enc = raw.rawValue
		let dec = Packet(rawValue: enc)
		#expect(dec == .some(raw))
	}
}
