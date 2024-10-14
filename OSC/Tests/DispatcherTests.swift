import Testing
import Synchronization
@testable import OSC
@Suite
struct RouterTests {
	@Test
	func serverRegex() throws {
		let expectation = Atomic<Int>(0)
		let dispatcher = Dispatcher<IPv4Endpoint>()
		// accept multiple address, we can capture the elements by using regex
		dispatcher.invoke(for: /^\/root\/sub(?<number>.)$/) { address, _, _ in
			// evaluate captured values
			let status = Int(address.number).map((1...4).contains)
			#expect(status == .some(true))
			expectation.add(1, ordering: .acquiringAndReleasing)
		}
		// unmatch
		dispatcher.invoke(for: /^\/root\/sud.$/) { _, _, _ in
			Issue.record()
		}
		// we can use glob style, same as osc
		dispatcher.invoke(for: try Regex(osc: "/root/sub?")) { _, _, _ in
			expectation.add(1, ordering: .acquiringAndReleasing)
		}
		dispatcher.receive(("/root/sub1", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub2", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub3", IPv4Endpoint(addr: .any, port: .any)))
		dispatcher.receive(("/root/sub4", IPv4Endpoint(addr: .any, port: .any)))
		let count = expectation.load(ordering: .acquiring)
		#expect(count == 8)
	}
	// In this scenario, a message will be accepted by multiple handlers
	// a message /root/sub?/{foo,bar} will be accepted by multiple handlers /root/sub1/foo, /root/sub2/bar
	@Test
	func clientQuery() throws {
		let expectation = Atomic<Int>(0)
		let dispatcher = Dispatcher<IPv4Endpoint>()
		dispatcher.invoke(for: "/root/sub1/foo") { _, _, _ in
			expectation.add(1, ordering: .acquiringAndReleasing)
		}
		dispatcher.invoke(for: "/root/sub2/bar") { _, _, _ in
			expectation.add(1, ordering: .acquiringAndReleasing)
		}
		// not recept
		dispatcher.invoke(for: "/root/sub3/foobar") { _, _, _ in
			Issue.record()
		}
		// call multiple resources like query, by using glob form
		dispatcher.receive(("/root/sub?/{foo,bar}", IPv4Endpoint(addr: .any, port: .any)))
		let count = expectation.load(ordering: .acquiring)
		#expect(count == 2)
	}
}
