//
//  UdpSocket.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
import struct Foundation.Data
import protocol Foundation.ContiguousBytes
import Network
import os.log
public final class UdpSocket<Endpoint: IPEndpoint>: Sendable {
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
extension UdpSocket {
	@inlinable
	public static var new: Result<UdpSocket, NWError> {
		Int32.socket(domain: Endpoint.family, type: SOCK_DGRAM, protocol: IPPROTO_UDP).map(Self.init(descriptor:))
	}
}
extension UdpSocket {
	@discardableResult
	public func set(reuseAddr value: Bool) -> Result<(), NWError> {
		handle.setsockopt(level: SOL_SOCKET, name: SO_REUSEADDR, value: value ? 1 : Int32.zero)
	}
	@discardableResult
	public func set(reusePort value: Bool) -> Result<(), NWError> {
		handle.setsockopt(level: SOL_SOCKET, name: SO_REUSEPORT, value: value ? 1 : Int32.zero)
	}
}
extension UdpSocket {
	@discardableResult
	public func set(timeoutRecv value: Duration) -> Result<(), NWError> {
		handle.set(timeoutRecv: value)
	}
	@discardableResult
	public func set(timeoutSend value: Duration) -> Result<(), NWError> {
		handle.set(timeoutSend: value)
	}
}
extension UdpSocket {
	@inlinable
	@discardableResult
	public func bind(on endpoint: Endpoint) -> Result<(), NWError> {
		handle.bind(on: endpoint)
	}
}
extension UdpSocket {
	@inlinable
	@discardableResult
	public func send(data: some ContiguousBytes, to endpoint: Endpoint) -> Result<Int, NWError> {
		handle.send(data: data, to: endpoint)
	}
	@discardableResult
	public func recv(count: Int) -> Result<(Data, Endpoint), NWError> {
		handle.recv(count: count)
	}
}
extension UdpSocket where Endpoint.Address == IPv4Address {
	@discardableResult
	public func join(multicast address: Endpoint.Address, via interface: Endpoint.Address) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IP, name: IP_ADD_MEMBERSHIP, value: ip_mreq(
			imr_multiaddr: address.rawValue.withUnsafeBytes { $0.load(as: in_addr.self) },
			imr_interface: interface.rawValue.withUnsafeBytes { $0.load(as: in_addr.self) }
		))
	}
	@discardableResult
	public func leave(multicast address: Endpoint.Address, via interface: Endpoint.Address) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IP, name: IP_DROP_MEMBERSHIP, value: ip_mreq(
			imr_multiaddr: address.rawValue.withUnsafeBytes { $0.load(as: in_addr.self) },
			imr_interface: interface.rawValue.withUnsafeBytes { $0.load(as: in_addr.self) }
		))
	}
	@discardableResult
	public func set(multicastTTL value: UInt8) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IP, name: IP_MULTICAST_TTL, value: value)
	}
}
extension UdpSocket where Endpoint.Address == IPv6Address {
	@discardableResult
	public func join(multicast address: Endpoint.Address, via interface: UInt32) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IPV6, name: IPV6_JOIN_GROUP, value: ipv6_mreq(
			ipv6mr_multiaddr: address.rawValue.withUnsafeBytes { $0.load(as: in6_addr.self) },
			ipv6mr_interface: interface))
	}
	@discardableResult
	public func leave(multicast address: Endpoint.Address, via interface: UInt32) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IPV6, name: IPV6_LEAVE_GROUP, value: ipv6_mreq(
			ipv6mr_multiaddr: address.rawValue.withUnsafeBytes { $0.load(as: in6_addr.self) },
			ipv6mr_interface: interface))
	}
	@discardableResult
	public func set(multicastTTL value: UInt32) -> Result<(), NWError> {
		handle.setsockopt(level: IPPROTO_IPV6, name: IPV6_MULTICAST_HOPS, value: value)
	}
}
extension UdpSocket: Identifiable {
	@inlinable
	public var id: Int32 {
		handle
	}
}
extension UdpSocket: Hashable {
	@inlinable
	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}
	@inlinable
	public static func==(lhs: UdpSocket, rhs: UdpSocket) -> Bool {
		lhs.handle == rhs.handle
	}
}
