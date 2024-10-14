import Testing
import Foundation
import Network
import Synchronization
@testable import Socket
@Suite
struct TcpStreamTests {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 32) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	func scenario<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
		try await withThrowingDiscardingTaskGroup { group in
			let server = TcpStream.Incoming(on: endpoint, count: 2)
			group.addTask {
				let status = Atomic(false)
				for try await (client, request) in server.values.prefix(1) where request.addr == endpoint.addr {
					for try await packet in client.values.prefix(1) {
						#expect(packet == req)
						status.store(true, ordering: .releasing)
					}
					let sent = try await client.send(data: res).value
					#expect(sent == res.count)
				}
				let done = status.load(ordering: .acquiring)
				#expect(done)
			}
			try await Task.sleep(for: .milliseconds(42))
			let client = try await TcpStream.Connect(to: endpoint).value
			group.addTask {
				let status = Atomic(false)
				let sent = try await client.send(data: req).value
				#expect(sent == req.count)
				for try await packet in client.values.prefix(1) {
					#expect(packet == res)
					status.store(true, ordering: .releasing)
				}
				let done = status.load(ordering: .acquiring)
				#expect(done)
			}
		}
	}
	func clientserver<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
		try await withThrowingDiscardingTaskGroup { group in
			let server = TcpStream.Incoming(on: endpoint, count: 1)
			group.addTask {
				for try await (client, peer) in server.values.prefix(1) {
					#expect(peer.addr == endpoint.addr)
					for try await packet in client.values.prefix(1) {
						#expect(packet == req)
					}
					let sent = try await client.send(data: res).value
					#expect(sent == res.count)
				}
			}
			try await Task.sleep(for: .milliseconds(42))
			let client = try await TcpStream.Connect(to: endpoint, timeout: .seconds(3)).value
			group.addTask {
				for try await packet in client.values.prefix(1) {
					#expect(packet == res)
				}
			}
			let sent = try await client.send(data: req).value
			#expect(sent == req.count)
		}
	}
	func serverclient<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
		try await withThrowingDiscardingTaskGroup { group in
			let server = TcpStream.Incoming(on: endpoint, count: 1)
			group.addTask {
				for try await (client, peer) in server.values.prefix(1) {
					#expect(peer.addr == endpoint.addr)
					for try await packet in client.values.prefix(1) {
						#expect(packet == res)
					}
					let sent = try await client.send(data: req).value
					#expect(sent == req.count)
				}
			}
			try await Task.sleep(for: .milliseconds(42))
			let client = try await TcpStream.Connect(to: endpoint, timeout: .seconds(3)).value
			group.addTask {
				for try await packet in client.values.prefix(1) {
					#expect(packet == req)
				}
			}
			let sent = try await client.send(data: res).value
			#expect(sent == res.count)
		}
 	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v4() async throws {
		try await scenario(on: IPv4Endpoint(addr: .loopback, port: 8194))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v6() async throws {
		try await scenario(on: IPv6Endpoint(addr: .loopback, port: 8196))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v4ClientServer() async throws {
		try await clientserver(on: IPv4Endpoint(addr: .loopback, port: 16386))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v6ClientServer() async throws {
		try await clientserver(on: IPv6Endpoint(addr: .loopback, port: 16388))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v4ServerClient() async throws {
		try await serverclient(on: IPv4Endpoint(addr: .loopback, port: 16387))
	}
	@Test(TimeLimitTrait.timeLimit(.minutes(1)))
	func v6ServerClient() async throws {
		try await serverclient(on: IPv6Endpoint(addr: .loopback, port: 16389))
	}
}
//final class TcpStreamTests: XCTestCase {
//	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 32) {
//		arc4random_buf($0.baseAddress, $0.count)
//		$1 = $0.count
//	})
//	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
//		arc4random_buf($0.baseAddress, $0.count)
//		$1 = $0.count
//	})
//	func scenario<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
//		let expectation = XCTestExpectation()
//		expectation.expectedFulfillmentCount = 2
//		let server = TcpStream.Incoming(on: endpoint, count: 2)
//		Task {
//			for try await (client, request) in server.values.prefix(1) where request.addr == endpoint.addr {
//				for try await packet in client.values.prefix(1) where packet == req {
//					expectation.fulfill()
//				}
//				let sent = try await client.send(data: res).value
//				XCTAssertEqual(sent, res.count)
//			}
//		}
//		try await Task.sleep(for: .milliseconds(1))
//		let client = try await TcpStream.Connect(to: endpoint).value
//		let sent = try await client.send(data: req).value
//		XCTAssertEqual(sent, req.count)
//		for try await packet in client.values.prefix(1) where packet == res {
//			expectation.fulfill()
//		}
//		await fulfillment(of: [expectation])
//	}
//	func clientserver<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
//		let request = XCTestExpectation(description: "request")
//		let response = XCTestExpectation(description: "response")
//		let server = TcpStream.Incoming(on: endpoint, count: 1)
//		Task {
//			for try await (client, peer) in server.values.prefix(1) {
//				XCTAssertEqual(peer.addr, endpoint.addr)
//				Task {
//					for try await packet in client.values.prefix(1) where packet == req {
//						request.fulfill()
//					}
//				}
//				let sent = try await client.send(data: res).value
//				XCTAssertEqual(sent, res.count)
//			}
//		}
//		let client = try await
//		TcpStream.Connect(to: endpoint).value
//		Task {
//			for try await packet in client.values.prefix(1) where packet == res {
//				response.fulfill()
//			}
//		}
//		let sent = try await client.send(data: req).value
//		XCTAssertEqual(sent, req.count)
//		await fulfillment(of: [request, response], timeout: 6)
//	}
//	func serverclient<Endpoint: IPEndpoint>(on endpoint: Endpoint) async throws {
//		let request = XCTestExpectation(description: "request")
//		let response = XCTestExpectation(description: "response")
//		let server = TcpStream.Incoming(on: endpoint, count: 1)
//		Task {
//			for try await (client, peer) in server.values.prefix(1) {
//				XCTAssertEqual(peer.addr, endpoint.addr)
//				Task {
//					for try await packet in client.values.prefix(1) where packet == res {
//						request.fulfill()
//					}
//				}
//				let sent = try await client.send(data: req).value
//				XCTAssertEqual(sent, req.count)
//			}
//		}
//		let client = try await TcpStream.Connect(to: endpoint, timeout: .seconds(3)).value
//		Task {
//			for try await packet in client.values.prefix(1) where packet == req {
//				response.fulfill()
//			}
//		}
//		let sent = try await client.send(data: res).value
//		XCTAssertEqual(sent, res.count)
//		await fulfillment(of: [request], timeout: 6)
//	}
////	func testV4() async throws {
////		try await scenario(on: IPv4Endpoint(addr: .loopback, port: 8194))
////	}
////	func testV6() async throws {
////		try await scenario(on: IPv6Endpoint(addr: .loopback, port: 8196))
////	}
////	func testServerClientV4() async throws {
////		try await serverclient(on: IPv4Endpoint(addr: .loopback, port: 16385))
////	}
////	func testClientServerv4() async throws {
////		try await clientserver(on: IPv4Endpoint(addr: .loopback, port: 16386))
////	}
////	func testServerClientV6() async throws {
////		try await serverclient(on: IPv6Endpoint(addr: .loopback, port: 16387))
////	}
////	func testClientServerv6() async throws {
////		try await clientserver(on: IPv6Endpoint(addr: .loopback, port: 16388))
////	}
//}
