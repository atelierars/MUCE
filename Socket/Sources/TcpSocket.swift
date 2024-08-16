//
//  TcpSocket.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
import struct Foundation.Data
import protocol Foundation.ContiguousBytes
import Network
import os.log
public final class TcpSocket<Endpoint: IPEndpoint>: Sendable {
	@usableFromInline
	let handle: Int32
	@inlinable
	init(descriptor: Int32) {
		handle = descriptor
	}
	deinit {
		switch handle.close() {
		case.success(()):
			break
		case.failure(let error):
			os_log(.debug, "%s", error.localizedDescription)
		}
	}
}
extension TcpSocket {
	@inlinable
	public static var new: Result<TcpSocket, NWError> {
		switch Darwin.socket(Endpoint.family, SOCK_STREAM, IPPROTO_TCP) {
		case ..<0:
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		case let descriptor:
			.success(.init(descriptor: descriptor))
		}
	}
}
extension TcpSocket {
	@discardableResult
	public func set(reuseAddr value: Bool) -> Result<(), NWError> {
		handle.setsockopt(level: SOL_SOCKET, name: SO_REUSEADDR, value: value ? 1 : Int32.zero)
	}
	@discardableResult
	public func set(reusePort value: Bool) -> Result<(), NWError> {
		handle.setsockopt(level: SOL_SOCKET, name: SO_REUSEPORT, value: value ? 1 : Int32.zero)
	}
}
extension TcpSocket {
	@discardableResult
	public func set(timeoutRecv value: Duration) -> Result<(), NWError> {
		handle.set(timeoutRecv: value)
	}
	@discardableResult
	public func set(timeoutSend value: Duration) -> Result<(), NWError> {
		handle.set(timeoutSend: value)
	}
}
extension TcpSocket {
	@discardableResult
	public func bind(on endpoint: Endpoint) -> Result<(), NWError> {
		handle.bind(on: endpoint)
	}
}
extension TcpSocket {
	@inlinable
	@discardableResult
	public func send(data: some ContiguousBytes) -> Result<Int, NWError> {
		handle.send(data: data)
	}
	@inlinable
	@discardableResult
	public func send<T>(data: Array<T>) -> Result<Int, NWError> {
		handle.send(data: data)
	}
}
extension TcpSocket {
	@inlinable
	public func recv(count: Int) -> Result<Data, NWError> {
		handle.recv(count: count)
	}
	@inlinable
	public func recv<T>(count: Int) -> Result<Array<T>, NWError> {
		handle.recv(count: count)
	}
}
extension TcpSocket {
	@inlinable
	@discardableResult
	public func connect(to endpoint: Endpoint) -> Result<(), NWError> {
		handle.connect(to: endpoint)
	}
}
extension TcpSocket {
	@inlinable
	@discardableResult
	public func listen(count: Int) -> Result<(), NWError> {
		handle.listen(count: count)
	}
}
extension TcpSocket {
	@inlinable
	public func accept() -> Result<(TcpSocket, Endpoint), NWError> {
		handle.accept().map { (.init(descriptor: $0), $1) }
	}
}
extension TcpSocket {
	@inlinable
	public var endpoint: Result<Endpoint, NWError> {
		handle.getpeername()
	}
}
extension TcpSocket: Identifiable {
	@inlinable
	public var id: Int32 {
		handle
	}
}
extension TcpSocket: Hashable {
	@inlinable
	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}
	@inlinable
	public static func == (lhs: TcpSocket<Endpoint>, rhs: TcpSocket<Endpoint>) -> Bool {
		lhs.id == rhs.id
	}
}
