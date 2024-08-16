import XCTest
import CoreMedia
@testable import Chrono
final class CMTimeTests: XCTestCase {
	func testDiv() {
		let a = CMTime(seconds: -1.25, preferredTimescale: 1 << 17 - 1)
		let b = CMTime(seconds: 3.125, preferredTimescale: 1 << 19 - 1)
		let c = CMTimeDivApprox(a, b)
		XCTAssertEqual(c.seconds, a.seconds / b.seconds, accuracy: 1e-6)
	}
	func testMod() {
		let a = CMTime(seconds: -1.3, preferredTimescale: 1 << 17 - 1)
		let b = CMTime(seconds: 2.9, preferredTimescale: 1 << 19 - 1)
		let c = CMTimeModApprox(a, b)
		XCTAssertEqual(c.seconds, fmod(a.seconds, b.seconds), accuracy: 1e-6)
	}
}
