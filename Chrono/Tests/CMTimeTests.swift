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
		#expect(fma(a.seconds, recip(b.seconds), -c.seconds).magnitude < 1e-5, "\(c.seconds) vs \(a.seconds / b.seconds)")
	}
	@Test
	func mod() {
		let a = CMTime(seconds: .random(in: 1...9), preferredTimescale: .init((1 << 31) - 1))
		let b = CMTime(seconds: .random(in: 1...9), preferredTimescale: 1 << 19 - 1)
		let c = CMTimeModApprox(a, b)
		let d = a.seconds.truncatingRemainder(dividingBy: b.seconds)
		#expect((c.seconds - d).magnitude < 1e-5, "\(c.seconds) vs \(a.seconds.truncatingRemainder(dividingBy: b.seconds)) of \(a.seconds), \(b.seconds)")
	}
	@Test(arguments: [
		(CMTime(value: 17, timescale: 8), ( 2.5, 2.5, 2.0, 2.0, 2.0)), // 2.25 -> ( 2.5, 2.0, 2.0, 2.0)
		(CMTime(value: 16, timescale: 8), ( 2.0, 2.0, 2.0, 2.0, 2.0)), // 2.00 -> ( 2.0, 2.0, 2.0, 2.0)
		(CMTime(value: 15, timescale: 8), ( 2.0, 2.0, 1.5, 2.0, 1.5)), // 1.75 -> ( 2.0, 1.5, 2.0, 1.5)
		(CMTime(value:  0, timescale: 8), ( 0.0, 0.0, 0.0, 0.0, 0.0)),
		(CMTime(value:-15, timescale: 8), (-2.0,-1.5,-2.0,-2.0,-1.5)), //-1.75 -> (-1.5,-1.5,-2.0,-1.5)
		(CMTime(value:-16, timescale: 8), (-2.0,-2.0,-2.0,-2.0,-2.0)), //-2.00 -> (-2.0,-2.0,-2.0,-2.0)
		(CMTime(value:-17, timescale: 8), (-2.5,-2.0,-2.5,-2.0,-2.0)), //-2.25 -> (-2.0,-2.0,-2.0,-2.0)
	] as Array<(CMTime, (Float64, Float64, Float64, Float64, Float64))>)
	func quantise(query: CMTime, result: (Float64, Float64, Float64, Float64, Float64)) {
		#expect(query.quantise(by: .init(value: 1, timescale: 2), rounding: .infinite).seconds == result.0)
		#expect(query.quantise(by: .init(value: 1, timescale: 2), rounding: .positive).seconds == result.1)
		#expect(query.quantise(by: .init(value: 1, timescale: 2), rounding: .negative).seconds == result.2)
		#expect(query.quantise(by: .init(value: 1, timescale: 2), rounding: .nearest).seconds == result.3)
		#expect(query.quantise(by: .init(value: 1, timescale: 2), rounding: .zero).seconds == result.4)
	}
}
