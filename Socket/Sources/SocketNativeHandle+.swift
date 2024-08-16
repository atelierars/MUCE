//
//  SocketNativeHandle+.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
import Darwin
import struct Foundation.Data
import typealias Foundation.SocketNativeHandle
import enum Network.NWError
import protocol Foundation.ContiguousBytes
import class Combine.Future
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	static func socket(domain: Int32, type: Int32, protocol: Int32) -> Result<Self, NWError> {
		switch Darwin.socket(domain, type, `protocol`) {
		case ..<0:
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		case let descriptor:
			.success(descriptor)
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func close() -> Result<(), NWError> {
		Darwin.close(self) == .zero ?
			.success(()) :
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func bind(on endpoint: some SocketEndpoint) -> Result<(), NWError> {
		withUnsafeBytes(of: endpoint) {
			Darwin.bindresvport_sa(self, .init(mutating: $0.assumingMemoryBound(to: sockaddr.self).baseAddress)) == .zero ?
				.success(()) :
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func setsockopt<T>(level: Int32, name: Int32, value: T) -> Result<(), NWError> {
		withUnsafeBytes(of: value) {
			Darwin.setsockopt(self, level, name, $0.baseAddress, .init($0.count)) == .zero ?
				.success(()) :
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		}
	}
	@inline(__always)
	@inlinable
	func getsockopt<R>(level: Int32, name: Int32) -> Result<R, NWError> {
		withUnsafeTemporaryAllocation(byteCount: MemoryLayout<R>.size, alignment: MemoryLayout<R>.alignment) {
			var size = socklen_t($0.count)
			return Darwin.getsockopt(self, level, name, $0.baseAddress, &size) == .zero ?
				.success($0.load(as: R.self)) :
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func recv<Endpoint: SocketEndpoint>(count: Int) -> Result<(Data, Endpoint), NWError> {
		withUnsafeTemporaryAllocation(byteCount: MemoryLayout<Endpoint>.size, alignment: MemoryLayout<Endpoint>.alignment) { memory in
			var size = socklen_t(memory.count)
			var data = Data(count: count)
			let done = data.withUnsafeMutableBytes {
				Darwin.recvfrom(self, $0.baseAddress, $0.count, 0, memory.assumingMemoryBound(to: sockaddr.self).baseAddress, &size)
			}
			return switch done {
			case ..<0:
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
			case let size:
				.success((data.prefix(size), memory.load(as: Endpoint.self)))
			}
		}
	}
	@inline(__always)
	@inlinable
	func recv<Endpoint: SocketEndpoint, T>(count: Int) -> Result<(Array<T>, Endpoint), NWError> {
		withUnsafeTemporaryAllocation(byteCount: MemoryLayout<Endpoint>.size, alignment: MemoryLayout<Endpoint>.alignment) { memory in
			var size = socklen_t(memory.count)
			var data = Data(count: count)
			let recv = Array<T>(unsafeUninitializedCapacity: count) {
				$1 = Darwin.recvfrom(self, $0.baseAddress, $0.count * MemoryLayout<T>.stride, 0, memory.assumingMemoryBound(to: sockaddr.self).baseAddress, &size) / MemoryLayout<T>.stride
			}
			return switch recv.count {
			case ..<0:
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
			case let size:
				.success((recv, memory.load(as: Endpoint.self)))
			}
		}
	}
	@inline(__always)
	@inlinable
	func send(data: some ContiguousBytes, to endpoint: some SocketEndpoint) -> Result<Int, NWError> {
		withUnsafeBytes(of: endpoint) { memory in
			data.withUnsafeBytes {
				switch Darwin.sendto(self, $0.baseAddress, $0.count, 0, memory.assumingMemoryBound(to: sockaddr.self).baseAddress, .init(memory.count)) {
				case ..<0:
					.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
				case let size:
					.success(size)
				}
			}
		}
	}
	@inline(__always)
	@inlinable
	func send<T>(data: Array<T>, to endpoint: some SocketEndpoint) -> Result<Int, NWError> {
		data.withUnsafeBytes { send(data: $0, to: endpoint) }.map { $0 / MemoryLayout<T>.stride }
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func recv(count: Int) -> Result<Data, NWError> {
		var data = Data(count: count)
		let done = data.withUnsafeMutableBytes {
			Darwin.recv(self, $0.baseAddress, $0.count, 0)
		}
		return switch done {
		case ..<0:
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		case let size:
			.success(data.prefix(size))
		}
	}
	@inline(__always)
	@inlinable
	func recv<T>(count: Int) -> Result<Array<T>, NWError> {
		let recv = Array<T>(unsafeUninitializedCapacity: count) {
			$1 = Darwin.recv(self, $0.baseAddress, $0.count * MemoryLayout<T>.stride, 0) / MemoryLayout<T>.stride
		}
		return switch recv.count {
		case ..<0:
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		default:
			.success(recv)
		}
	}
	@inline(__always)
	@inlinable
	func send(data: some ContiguousBytes) -> Result<Int, NWError> {
		data.withUnsafeBytes {
			switch Darwin.send(self, $0.baseAddress, $0.count, 0) {
			case ..<0:
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
			case let size:
				.success(size)
			}
		}
	}
	@inline(__always)
	@inlinable
	func send<T>(data: Array<T>) -> Result<Int, NWError> {
		data.withUnsafeBytes {
			switch Darwin.send(self, $0.baseAddress, $0.count, 0) {
			case ..<0:
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
			case let size:
				.success(size)
			}
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func connect(to endpoint: some SocketEndpoint) -> Result<(), NWError> {
		withUnsafeBytes(of: endpoint) {
			Darwin.connect(self, $0.assumingMemoryBound(to: sockaddr.self).baseAddress, .init($0.count)) == .zero ?
				.success(()) :
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		}
	}
	@inlinable
	@inline(__always)
	func listen(count: Int) -> Result<(), NWError> {
		Darwin.listen(self, .init(count)) == .zero ?
			.success(()) :
			.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
	}
	@inlinable
	@inline(__always)
	func accept<Endpoint: SocketEndpoint>() -> Result<(Int32, Endpoint), NWError> {
		withUnsafeTemporaryAllocation(byteCount: MemoryLayout<Endpoint>.size, alignment: MemoryLayout<Endpoint>.alignment) {
			var size = socklen_t($0.count)
			return switch Darwin.accept(self, $0.assumingMemoryBound(to: sockaddr.self).baseAddress, &size) {
			case ..<0:
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
			case let descriptor:
				.success((descriptor, $0.load(as: Endpoint.self)))
			}
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func getpeername<Endpoint: SocketEndpoint>() -> Result<Endpoint, NWError> {
		withUnsafeTemporaryAllocation(byteCount: MemoryLayout<Endpoint>.size, alignment: MemoryLayout<Endpoint>.alignment) {
			var size = socklen_t($0.count)
			return Darwin.getpeername(self, $0.assumingMemoryBound(to: sockaddr.self).baseAddress, &size) == .zero ?
				.success($0.load(as: Endpoint.self)) :
				.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
		}
	}
}
extension SocketNativeHandle {
	@inline(__always)
	@inlinable
	func set(timeoutRecv value: Duration) -> Result<(), NWError> {
		setsockopt(level: SOL_SOCKET, name: SO_RCVTIMEO, value: timeval(value))
	}
	@inlinable
	@inline(__always)
	func set(timeoutSend value: Duration) -> Result<(), NWError> {
		setsockopt(level: SOL_SOCKET, name: SO_SNDTIMEO, value: timeval(value))
	}
}
