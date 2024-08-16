import XCTest
import Network
import Combine
@testable import Socket
final class ConnectionTests: XCTestCase {
	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
		arc4random_buf($0.baseAddress, $0.count)
		$1 = $0.count
	})
	func testUdpMessage() async throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 2
		Task {
			for try await client in Connection.Incoming(on: 9841, with: .udp).values.prefix(1) {
				for try await packet in client.recv(count: 1024).values.prefix(1) where packet == req {
					client.send(message: res)
					expectation.fulfill()
				}
			}
		}
		try await Task.sleep(for: .seconds(1))
		let client = Connection(to: .hostPort(host: .ipv4(.loopback), port: 9841), with: .udp)
		Task {
			for try await packet in client.recv(count: 1024).values.prefix(1) where packet == res {
				expectation.fulfill()
			}
		}
		try await Task.sleep(for: .seconds(0))
		client.send(message: req)
		await fulfillment(of: [expectation], timeout: 30)
	}
	func testTcpMessage() async throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 2
		Task {
			for try await client in Connection.Incoming(on: 9842, with: .tcp).values.prefix(1) {
				for try await packet in client.recv(count: 1024).values.prefix(1) where packet == req {
					client.send(message: res)
					expectation.fulfill()
				}
			}
		}
		try await Task.sleep(for: .seconds(1))
		let client = Connection(to: .hostPort(host: .ipv4(.loopback), port: 9842), with: .tcp)
		Task {
			for try await packet in client.recv(count: 1024).values.prefix(1) where packet == res {
				expectation.fulfill()
			}
		}
		try await Task.sleep(for: .seconds(0))
		client.send(message: req)
		await fulfillment(of: [expectation], timeout: 30)
	}
	func testTcpStream() async throws {
		let expectation = XCTestExpectation()
		expectation.expectedFulfillmentCount = 5
		let stream = PassthroughSubject<Data, Never>()
		Task {
			for try await client in Connection.Incoming(on: 9843, with: .tcp).values.prefix(1) {
				for try await packet in client.recv(count: 1024).values.prefix(1) where packet == req {
					for try await status in client.send(stream: stream).values {
						
					}
				}
				expectation.fulfill()
			}
		}
		try await Task.sleep(for: .seconds(1))
		let client = Connection(to: .hostPort(host: .ipv4(.loopback), port: 9843), with: .tcp)
		Task {
			for try await packet in client.recv(count: 1024).values.prefix(4) {
				expectation.fulfill()
			}
		}
		try await Task.sleep(for: .milliseconds(10))
		client.send(message: req)
		try await Task.sleep(for: .milliseconds(10))
		stream.send(.init(count: 4))
		try await Task.sleep(for: .milliseconds(10))
		stream.send(.init(count: 4))
		try await Task.sleep(for: .milliseconds(10))
		stream.send(.init(count: 4))
		try await Task.sleep(for: .milliseconds(10))
		stream.send(.init(count: 4))
		try await Task.sleep(for: .milliseconds(10))
		stream.send(completion: .finished)
		await fulfillment(of: [expectation], timeout: 30)
	}
}
//final class ConnectionTests: XCTestCase {
//	let req = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
//		arc4random_buf($0.baseAddress, $0.count)
//		$1 = $0.count
//	})
//	let res = Data(Array<UInt8>(unsafeUninitializedCapacity: 16) {
//		arc4random_buf($0.baseAddress, $0.count)
//		$1 = $0.count
//	})
//	func scenario(at endpoint: (NWEndpoint.Host, NWEndpoint.Port), with protocol: NWParameters) async throws {
//		let request = XCTestExpectation(description: "request")
//		let response = XCTestExpectation(description: "response")
//		let server = try Connection.Incoming(on: endpoint.1, with: `protocol`)
//		Task {
//			for try await client in server.prefix(1) {
//				for try await (packet, _) in client.receiving(count: 1024).prefix(1) where packet == req {
//					request.fulfill()
//				}
//				try await client.send(data: res, on: .global())
//			}
//		}
//		let client = Connection(to: .hostPort(host: endpoint.0, port: endpoint.1), by: `protocol`)
//		Task {
//			try await client.send(data: req, on: .global())
//			for try await (packet, _) in client.receiving(count: 1024).prefix(1) where packet == res {
//				response.fulfill()
//			}
//		}
//		await fulfillment(of: [request, response], timeout: 30)
//	}
//	func testUdpV4Connection() async throws {
//		try await scenario(at: (.ipv4(.loopback), 8193), with: .udp)
//	}
//	func testUdpV6Connection() async throws {
//		try await scenario(at: (.ipv6(.loopback), 8194), with: .udp)
//	}
//	func testTcpV4Connection() async throws {
//		try await scenario(at: (.ipv4(.loopback), 8195), with: .tcp)
//	}
//	func testTcpV6Connection() async throws {
//		try await scenario(at: (.ipv6(.loopback), 8196), with: .tcp)
//	}
//	func recv(nw: NWConnection) {
//		nw.start(queue: .global())
//		nw.receiveMessage {
//			print(10, $0, $1, $2, $3)
//		}
//		nw.receiveMessage {
//			print(20, $0, $1, $2, $3)
//		}
//		nw.receiveMessage {
//			print(30, $0, $1, $2, $3)
//		}
//	}
//	func testDemo() async throws {
//		let server = try NWListener(using: .tcp, on: 9992)
//		server.newConnectionHandler = recv(nw:)
//		server.start(queue: .global())
//		let client = NWConnection(to: .hostPort(host: .ipv4(.loopback), port: 9992), using: .tcp)
//		client.start(queue: .global())
//		client.send(content: Data(count: 64), contentContext: .defaultStream, isComplete: false, completion: .contentProcessed{
//			print(1, $0)
//		})
//		try await Task.sleep(for: Duration.seconds(4))
//		client.send(content: Data(count: 64), contentContext: .defaultStream, isComplete: false, completion: .contentProcessed{
//			print(2, $0)
//		})
//		try await Task.sleep(for: Duration.seconds(4))
//		client.send(content: Data(), contentContext: .finalMessage, isComplete: false, completion: .contentProcessed{
//			print(3, $0)
//		})
//		try await Task.sleep(for: Duration.seconds(4))
//	}
//}
