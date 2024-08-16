import XCTest
import CoreMedia
import Socket
@testable import Chrono
final class SynchroniserTests: XCTestCase {
	func testUdpSync() async throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 5
		Task {
			let ticker = try Ticker()
			try ticker.set(time: .init(seconds: 5_000_000, preferredTimescale: 1))
			try ticker.set(rate: 1)
			for try await endpoint in ticker.udpSynchroniser(on: IPv4Endpoint(addr: .loopback, port: 32777)).values where endpoint.addr == .loopback {
//				print(endpoint)
			}
		}
		let ticker = try Ticker()
		let tocker = ticker.timer(for: .init(value: 4, timescale: 5))
		Task {
			for try await response in ticker.udpSynchroniser(to: IPv4Endpoint(addr: .loopback, port: 32777)).values {
//				print(response.seconds)
			}
		}
		Task {
			for try await time in tocker.values where CMTime(value: 5_000_000, timescale: 1) < time {
				expectation.fulfill()
			}
		}
		await fulfillment(of: [expectation], timeout: 90)
	}
}
