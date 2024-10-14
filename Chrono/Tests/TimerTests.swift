import Testing
import CoreMedia
import Synchronization
import Integer_
@testable import Chrono
@Suite
struct TimerTests {
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func interval() async throws {
		let counter = Atomic<Int>(0)
		let ticker = try Ticker()
		try ticker.set(time: .init(value: -9000, timescale: 30000))
		try ticker.set(rate: 1)
		let timer = ticker.timer(for: .init(value: 1001, timescale: 30000))
		for try await time in timer.values.prefix(20) {
			#expect(CMTimeModApprox(time, .init(value: 1001, timescale: 30000)) == .zero)
			counter.add(1, ordering: .acquiringAndReleasing)
		}
		#expect(counter.load(ordering: .acquiring) == 20)
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func offset() async throws {
		let ticker = try Ticker()
		let tocker = try Ticker(parent: ticker)
		try tocker.set(rate: 1.2)
		try tocker.set(time: .init(value: 300, timescale: 1), at: .init(seconds: 0, preferredTimescale: 1))
		try ticker.set(rate: 1.5)
		try ticker.set(time: .init(seconds: 100, preferredTimescale: 1))
		#expect((tocker.time.seconds - 420).magnitude < 1e-3)
	}
}
