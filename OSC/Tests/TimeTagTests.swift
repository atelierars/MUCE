import Testing
import CoreMedia
@testable import OSC
@Suite
struct TimeTagTests {
	@Test
	func immediately() {
		let time = TimeTag.immediately
		#expect(time.rawValue == 0)
	}
	@Test
	func integer() {
		let time = 100 as TimeTag
		#expect(time.seconds == 100)
	}
	@Test
	func real() {
		let time = 0.5 as TimeTag
		#expect(time.seconds == 0.5)
	}
	@Test
	func now() {
		let now = Date.now
		let tag = TimeTag(date: now)
		#expect(now.timeIntervalSince(.init(tag)).magnitude < 1e-5)
	}
	@Test
	func dur() async throws {
		let dur = Duration.milliseconds(3850)
		let tag = TimeTag(duration: dur)
		#expect((tag.seconds - 3.85).magnitude < 1e-5)
	}
	@Test
	func cmTime() {
		let tik = CMTime(value: 3300, timescale: 1000)
		let tag = TimeTag(time: tik)
		#expect((tag.seconds - tik.seconds).magnitude < 1e-5)
	}
}
