import Testing
import Socket
import CoreMedia
import Dispatch
import Synchronization
import Combine
@testable import Chrono
@Suite
struct SynchroniserTests {
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func udp() async throws {
		let ticker = try Ticker()
		let tocker = ticker.timer(for: .init(value: 4, timescale: 5))
		Task {
			let ticker = try Ticker()
			try ticker.set(time: .init(value: 5_000_000, timescale: 1))
			try ticker.set(rate: 1)
			for try await endpoint in ticker.udpSynchroniser(on: IPv4Endpoint(addr: .loopback, port: 32777)).values where endpoint.addr == .loopback {
			}
		}
		Task {
			let adj = Atomic<Int>(0)
			for try await response in ticker.udpSynchroniser(to: IPv4Endpoint(addr: .loopback, port: 32777)).values where 1 < response.seconds {
				adj.add(1, ordering: .acquiringAndReleasing)
			}
			#expect(adj.load(ordering: .acquiring) == 1)
		}
		let signal = try await Task {
			try await tocker.values.filter {
				CMTime(value: 5_000_000, timescale: 1) < $0
			}.prefix(5).reduce(into: Array<CMTime>()) {
				$0.append($1)
			}
		}.value
		#expect(signal.count == 5)
		#expect(signal.allSatisfy { CMTime(value: 5_000_000, timescale: 1) < $0 })
		#expect(signal.allSatisfy { $0.value % 4 == 0 })
	}
}
