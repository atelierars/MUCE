//
//  IPEndpoint.swift
//
//
//  Created by kotan.kn on 8/3/R6.
//
import struct Foundation.Data
import Network
@_exported import enum Network.NWError
public protocol IPEndpoint<Address>: SocketEndpoint {
	associatedtype Address: IPAddress & Equatable
	init(addr: Address, port: NWEndpoint.Port)
	var addr: Address { get }
	var port: NWEndpoint.Port { get }
}
public typealias IPv4Endpoint = sockaddr_in
extension sockaddr_in: @retroactive Equatable {}
extension sockaddr_in6: @retroactive Equatable {}
extension IPv4Endpoint: @unchecked @retroactive Sendable, IPEndpoint  {
	public static let family: Int32 = AF_INET
	@inlinable
	public init(addr: IPv4Address, port: NWEndpoint.Port) {
		self.init(
			sin_len: .init(INET_ADDRSTRLEN),
			sin_family: .init(AF_INET),
			sin_port: port.rawValue.bigEndian,
			sin_addr: addr.rawValue.withUnsafeBytes { $0.load(as: in_addr.self) },
			sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
		)
	}
	@inlinable
	public var addr: IPv4Address {
		withUnsafeBytes(of: sin_addr) {
			.init(.init($0), .none).unsafelyUnwrapped
		}
	}
	@inlinable
	public var port: NWEndpoint.Port {
		.init(rawValue: .init(bigEndian: sin_port)).unsafelyUnwrapped
	}
	@inlinable
	public var host: NWEndpoint.Host {
		.ipv4(addr)
	}
	@inlinable
	public var nwEndpoint: NWEndpoint {
		.hostPort(host: host, port: port)
	}
	public static func==(lhs: Self, rhs: Self) -> Bool {
		lhs.sin_len == .init(INET_ADDRSTRLEN) &&
		rhs.sin_len == .init(INET_ADDRSTRLEN) &&
		lhs.sin_family == rhs.sin_family &&
		lhs.sin_port == rhs.sin_port &&
		lhs.sin_addr.s_addr == rhs.sin_addr.s_addr
	}
}
extension IPv4Endpoint: @retroactive CustomStringConvertible {
	public var description: String {
		"\(nwEndpoint)"
	}
}
public typealias IPv6Endpoint = sockaddr_in6
extension IPv6Endpoint: @retroactive @unchecked Sendable, IPEndpoint {
	public static let family: Int32 = AF_INET6
	@inlinable
	public init(addr: IPv6Address, port: NWEndpoint.Port) {
		self.init(
			sin6_len: .init(INET6_ADDRSTRLEN),
			sin6_family: .init(AF_INET6),
			sin6_port: port.rawValue.bigEndian,
			sin6_flowinfo: 0,
			sin6_addr: addr.rawValue.withUnsafeBytes { $0.load(as: in6_addr.self) },
			sin6_scope_id: 0
		)
	}
	@inlinable
	public var addr: IPv6Address {
		withUnsafeBytes(of: sin6_addr) {
			.init(.init($0), .none).unsafelyUnwrapped
		}
	}
	@inlinable
	public var port: NWEndpoint.Port {
		.init(rawValue: .init(bigEndian: sin6_port)).unsafelyUnwrapped
	}
	@inlinable
	public var host: NWEndpoint.Host {
		.ipv6(addr)
	}
	@inlinable
	public var nwEndpoint: NWEndpoint {
		.hostPort(host: host, port: port)
	}
	public static func==(lhs: Self, rhs: Self) -> Bool {
		lhs.sin6_len == .init(INET6_ADDRSTRLEN) &&
		rhs.sin6_len == .init(INET6_ADDRSTRLEN) &&
		lhs.sin6_family == rhs.sin6_family &&
		lhs.sin6_port == rhs.sin6_port &&
		lhs.sin6_addr.__u6_addr.__u6_addr32 == rhs.sin6_addr.__u6_addr.__u6_addr32 &&
		lhs.sin6_scope_id == rhs.sin6_scope_id
	}
}
extension IPv6Endpoint: @retroactive CustomStringConvertible {
	public var description: String {
		"\(nwEndpoint)"
	}
}
