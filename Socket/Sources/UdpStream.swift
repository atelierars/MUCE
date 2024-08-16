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
import struct Network.IPv4Address
import struct Network.IPv6Address
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
extension UdpStream where Endpoint.Address == IPv4Address {
	@discardableResult
	public func join(multicast address: Endpoint.Address, via interface: Endpoint.Address) -> Result<(), NWError> {
		handle.join(multicast: address, via: interface)
	}
	@discardableResult
	public func leave(multicast address: Endpoint.Address, via interface: Endpoint.Address) -> Result<(), NWError> {
		handle.leave(multicast: address, via: interface)
	}
	@discardableResult
	public func set(multicastTTL count: UInt8) -> Result<(), NWError> {
		handle.set(multicastTTL: count)
	}
}
extension UdpStream where Endpoint.Address == IPv6Address {
	@discardableResult
	public func join(multicast address: Endpoint.Address, via interface: UInt32) -> Result<(), NWError> {
		handle.join(multicast: address, via: interface)
	}
	@discardableResult
	public func leave(multicast address: Endpoint.Address, via interface: UInt32) -> Result<(), NWError> {
		handle.leave(multicast: address, via: interface)
	}
	@discardableResult
	public func set(multicastTTL count: UInt32) -> Result<(), NWError> {
		handle.set(multicastTTL: count)
	}
}
extension UdpStream: Publisher {
	public typealias Output = (Data, Endpoint)
	public typealias Failure = NWError
	public func receive<S>(subscriber: S) where S : Subscriber, (Data, Endpoint) == S.Input, NWError == S.Failure {
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
