import Testing
import CoreMedia
import simd
@testable import Chrono
@Suite
struct CMTimeTests {
	@Test
	func div() {
		let a = CMTime(seconds: .random(in: 1...9), preferredTimescale: 1 << 19 - 1)
		let b = CMTime(seconds: .random(in: 1...9), preferredTimescale: .init((1 << 31) - 1))
		let c = CMTimeDivApprox(a, b)
		let d = fma(a.seconds, recip(b.seconds), -c.seconds)
		#expect(d.magnitude < 1e-5, "\(c.seconds) vs \(a.seconds / b.seconds)")
	}
	@Test
	func mod() {
		let a = CMTime(seconds: .random(in: 1...9), preferredTimescale: .init((1 << 31) - 1))
		let b = CMTime(seconds: .random(in: 1...9), preferredTimescale: 1 << 19 - 1)
		let c = CMTimeModApprox(a, b)
		let d = c.seconds - a.seconds.remainder(dividingBy: b.seconds)
		#expect(d.magnitude < 1e-5, "\(c.seconds) vs \(a.seconds.remainder(dividingBy: b.seconds))")
	}
}
