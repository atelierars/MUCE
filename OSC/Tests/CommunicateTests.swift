import Testing
import Synchronization
@testable import OSC
@Suite
struct CommunicateTests {
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func udp() async throws {
		let value = Atomic<Int>(0)
		let expectation = Task {
			let receiver = OSC.UdpReceiver(on: IPv4Endpoint(addr: .loopback, port: 5598))
			for try await (message, endpoint) in receiver.values.prefix(3) {
				#expect(endpoint.addr == .loopback)
				switch message {
				case try Regex(osc: "/address/{foo|bar}/?"):
					#expect(message.arguments.rawValue == [1,2.0,"3",false,true].rawValue)
					value.add(1, ordering: .acquiringAndReleasing)
				default:
					break
				}
			}
		}
		try await Task.sleep(for: Duration.milliseconds(42)) // dispatch coroutine
		let sender = OSC.UdpSender<IPv4Endpoint>()
		sender.send(packet: .Bundle(at: 0, packets: [
			.Message(address: "/address/foo/0", arguments: [1,2.0,"3",false,true]),
			.Message(address: "/address/bar/1", arguments: [1,2.0,"3",false,true]),
			.Message(address: "/address/foobar/2", arguments: [1,2.0,"3",false,true]),
		]), to: .init(addr: .loopback, port: 5598))
		try await expectation.result.get()
		let count = value.load(ordering: .acquiring)
		#expect(count == 2)
	}
}
