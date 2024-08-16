import XCTest
import CoreMedia
@testable import Chrono
final class TimerTests: XCTestCase {
//	func testInteval() async throws {
//		let ticker = try Ticker()
//		try ticker.set(time: .init(value: -9000, timescale: 30000))
//		try ticker.set(rate: -1)
//		let timer = ticker.timer(for: .init(value: 1001, timescale: 30000))
//		for try await time in timer.values.prefix(20) {
//			print(time.convertScale(30000, method: .default), ticker.time.convertScale(30000, method: .default))
//		}
//	}
	func testOffset() throws {
		let expectation = XCTestExpectation()
		let ticker = try Ticker()
		let tocker = try Ticker(parent: ticker)
		try ticker.set(rate: 1.5)
		try tocker.set(rate: 1.2)
		try tocker.set(time: .init(value: 300, timescale: 1), at: .init(seconds: 0, preferredTimescale: 1))
		let cancel = tocker.vendor.sink(receiveValue: {
			XCTAssertEqual($0.seconds, 420, accuracy: 0) // 300 + 100 * 1.2
			expectation.fulfill()
		})
		try ticker.set(time: .init(seconds: 100, preferredTimescale: 1))
		wait(for: [expectation], timeout: 0)
	}
}
