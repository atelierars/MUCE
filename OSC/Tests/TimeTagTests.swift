import XCTest
import CoreMedia
@testable import OSC
final class TimeTagTests: XCTestCase {
	func testImmediately() {
		let tag = TimeTag.immediately
		XCTAssertEqual(tag.rawValue, 0)
		XCTAssertEqual(TimeTag.immediately, 0)
	}
	func testInteger() {
		let time = 100 as TimeTag
		XCTAssertEqual(time.seconds, 100)
	}
	func testReal() {
		let time = 0.5 as TimeTag
		XCTAssertEqual(time.seconds, 0.5)
	}
	func testNow() {
		let now = Date.now
		let tag = TimeTag(date: now)
		XCTAssertEqual(Date(tag).timeIntervalSinceReferenceDate, now.timeIntervalSinceReferenceDate, accuracy: 1e-5)
	}
	func testDuration() {
		let dur = Duration.milliseconds(3850)
		let tag = TimeTag(duration: dur)
		XCTAssertEqual(tag.seconds, 3.85, accuracy: 1e-5)
	}
	func testCMTime() {
		let tik = CMTime(value: 3300, timescale: 1000)
		let tag = TimeTag(time: tik)
		XCTAssertEqual(tag.seconds, tik.seconds, accuracy: 1e-5)
	}
}
