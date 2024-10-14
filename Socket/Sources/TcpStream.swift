//
//  TcpStream.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
import struct Foundation.Data
import protocol Foundation.ContiguousBytes
import Dispatch
import Network
import Async_
import Combine
public struct TcpStream<Endpoint: IPEndpoint>: @unchecked Sendable {
	@usableFromInline
	let handle: TcpSocket<Endpoint>
	@usableFromInline
	let broker: Deferred<Publishers.HandleEvents<PassthroughSubject<Data, NWError>>>
}
extension TcpStream {
	fileprivate init(connected socket: TcpSocket<Endpoint>, on queue: Optional<DispatchQueue>) {
		handle = socket
		broker = Deferred {
			let broker = PassthroughSubject<Data, NWError>()
			let source = DispatchSource.makeReadSource(fileDescriptor: socket.handle, queue: queue)
			source.setEventHandler {
				switch socket.recv(count: .init(source.data)) {
				case.success(let recv):
					broker.send(recv)
				case.failure(let error):
					broker.send(completion: .failure(error))
				}
			}
			source.setCancelHandler {
				source.setEventHandler(handler: .none)
				source.setCancelHandler(handler: .none)
			}
			source.resume()
			return broker.handleEvents(receiveCancel: source.cancel)
		}
	}
}
extension TcpStream {
	public static func Connect(to endpoint: Endpoint, on queue: Optional<DispatchQueue> = .none, timeout: Duration = .seconds(3)) -> Future<TcpStream, NWError> {
		.init {
			let promise = unsafeBitCast($0, to: (@Sendable (Result<TcpStream<Endpoint>, NWError>) -> Void).self)
			(queue ?? .global()).async {
				promise(TcpSocket<Endpoint>.new
					.flatMap { socket in socket.set(timeoutRecv: timeout).map { socket } }
					.flatMap { socket in socket.set(timeoutSend: timeout).map { socket } }
					.flatMap { socket in socket.connect(to: endpoint).map { socket } }
					.map { .init(connected: $0, on: queue)}
				)
			}
		}
	}
}
extension TcpStream {
	public static func Incoming(on endpoint: Endpoint, count: Int, queue: Optional<DispatchQueue> = .none, timeout: Duration = .seconds(3)) -> some Publisher<(Self, Endpoint), NWError> {
		TcpSocket<Endpoint>.new
			.flatMap { socket in socket.set(reuseAddr: true).map { socket } }
			.flatMap { socket in socket.set(reuseAddr: true).map { socket } }
			.flatMap { socket in socket.set(timeoutRecv: timeout).map { socket } }
			.flatMap { socket in socket.set(timeoutSend: timeout).map { socket } }
			.flatMap { socket in socket.bind(on: endpoint).map { socket } }
			.flatMap { socket in socket.listen(count: count).map { socket } }
			.publisher
			.flatMap { socket in
				let broker = PassthroughSubject<(Self, Endpoint), NWError>()
				let source = DispatchSource.makeReadSource(fileDescriptor: socket.handle, queue: queue)
				source.setEventHandler {
					switch socket.accept() {
					case.success((let socket, let endpoint)):
						broker.send((Self(connected: socket, on: queue), endpoint))
					case.failure(let error):
						broker.send(completion: .failure(error))
					}
				}
				source.setCancelHandler {
					source.setEventHandler(handler: .none)
					source.setCancelHandler(handler: .none)
				}
				source.resume()
				return broker.handleEvents(receiveCancel: source.cancel)
			}
	}
//	public static func Incoming(on endpoint: Endpoint, count: Int, queue: Optional<DispatchQueue> = .none) -> AsyncThrowingStream<(Self, Endpoint), Error> {
//		.init { future in
//			Task {
//				let status = await TcpSocket<Endpoint>.new
//					.flatMap { socket in await socket.set(timeoutRecv: .seconds(3)).map { socket } }
//					.flatMap { socket in await socket.set(timeoutSend: .seconds(3)).map { socket } }
//					.flatMap { socket in await socket.set(reuseAddr: true).map { socket } }
//					.flatMap { socket in await socket.set(reusePort: true).map { socket } }
//					.flatMap { socket in await socket.bind(on: endpoint).map { socket } }
//					.flatMap { socket in await socket.listen(count: count).map { socket } }
//				switch status {
//				case.success(let socket):
//					let source = DispatchSource.makeReadSource(fileDescriptor: socket.handle)
//					future.onTermination = {
//						switch $0 {
//						case.cancelled,.finished:
//							source.cancel()
//							source.setEventHandler(handler: .none)
//						@unknown default:
//							assertionFailure()
//						}
//					}
//					source.setEventHandler {
//						Task {
//							await future.yield(with: socket.accept().map {
//								(.init(connectedSocket: $0, on: queue), $1)
//							}.mapError { $0 })
//						}
//					}
//					source.resume()
//				case.failure(let error):
//					future.finish(throwing: error)
//				}
//			}
//		}
//	}
}
extension TcpStream {
	@inlinable
	@discardableResult
	public func send(data: some ContiguousBytes) -> Future<Int, NWError> {
		.init {
			$0(handle.send(data: data))
		}
	}
	@inlinable
	@discardableResult
	public func send<T>(data: Array<T>) -> Future<Int, NWError> {
		.init {
			$0(handle.send(data: data))
		}
	}
}
extension TcpStream: Publisher {
	public typealias Output = Data
	public typealias Failure = NWError
	public func receive(subscriber: some Subscriber<Output, Failure>) {
		broker.receive(subscriber: subscriber)
	}
}
extension TcpStream: Identifiable {
	@inlinable
	public var id: Int32 {
		handle.handle
	}
}
extension TcpStream: Hashable {
	@inlinable
	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}
	@inlinable
	public static func == (lhs: TcpStream<Endpoint>, rhs: TcpStream<Endpoint>) -> Bool {
		lhs.id == rhs.id
	}
}
