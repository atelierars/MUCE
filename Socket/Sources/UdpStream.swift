//
//  UdpStream.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import struct Foundation.Data
import protocol Foundation.ContiguousBytes
import class Dispatch.DispatchSource
import class Dispatch.DispatchQueue
import protocol Dispatch.DispatchSourceRead
import Combine
public struct UdpStream<Endpoint: IPEndpoint>: @unchecked Sendable {
	@usableFromInline
	let handle: UdpSocket<Endpoint>
	@usableFromInline
	let vendor: Deferred<Publishers.HandleEvents<PassthroughSubject<(Data, Endpoint), NWError>>>
}
extension UdpStream {
	fileprivate init(socket: UdpSocket<Endpoint>, queue: Optional<DispatchQueue> = .none) {
		handle = socket
		vendor = Deferred {
			let broker = PassthroughSubject<(Data, Endpoint), NWError>()
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
extension UdpStream {
	public static func `Any`(on queue: Optional<DispatchQueue> = .none) -> Result<Self, NWError> {
		UdpSocket<Endpoint>.new
			.map { .init(socket: $0, queue: queue) }
	}
	public static func Incoming(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none) -> Result<Self, NWError> {
		UdpSocket<Endpoint>.new
			.flatMap { socket in socket.set(reuseAddr: true).map { socket } }
			.flatMap { socket in socket.set(reusePort: true).map { socket } }
			.flatMap { socket in socket.bind(on: endpoint).map { socket } }
			.map { .init(socket: $0, queue: queue) }
	}
}
extension UdpStream {
	@discardableResult
	public func set(timeoutRecv value: Duration) -> Result<(), NWError> {
		handle.set(timeoutRecv: value)
	}
	@discardableResult
	public func set(timeoutSend value: Duration) -> Result<(), NWError> {
		handle.set(timeoutSend: value)
	}
}
extension UdpStream {
	@discardableResult
	public func send(data: some ContiguousBytes, to endpoint: Endpoint) -> Result<Int, NWError> {
		handle.send(data: data, to: endpoint)
	}
}
extension UdpStream: Publisher {
	public typealias Output = (Data, Endpoint)
	public typealias Failure = NWError
	public func receive<S>(subscriber: S) where S : Subscriber, NWError == S.Failure, (Data, Endpoint) == S.Input {
		vendor.receive(subscriber: subscriber)
	}
}
extension UdpStream: Identifiable {
	@inlinable
	public var id: Int32 {
		handle.handle
	}
}
extension UdpStream: Hashable {
	@inlinable
	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}
	@inlinable
	public static func == (lhs: UdpStream<Endpoint>, rhs: UdpStream<Endpoint>) -> Bool {
		lhs.id == rhs.id
	}
}
