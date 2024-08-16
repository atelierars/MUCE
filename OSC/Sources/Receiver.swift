//
//  Receiver.swift
//  
//
//  Created by kotan.kn on 8/7/R6.
//
import Combine
import Socket
import Dispatch
import Foundation
import Network
@_exported import struct Socket.IPv4Endpoint
@_exported import struct Socket.IPv6Endpoint
//public func UdpReceiver<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none) -> AsyncCompactMapSequence<AsyncThrowingStream<(Data, Endpoint), Error>, (Packet, Endpoint)> {
//	UdpSocket.Incoming(on: endpoint, queue: queue).compactMap {(data, endpoint)in
//		Packet(rawValue: data).map { ($0, endpoint) }
//	}
//}
public func UdpReceiver<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none) -> some Publisher<(Endpoint, String, Array<Argument>), NWError> {
	UdpStream.Incoming(on: endpoint, queue: queue)
		.publisher
		.flatMap { $0 }
		.compactMap { (data, endpoint) in Packet(rawValue: data).map { ($0, endpoint) } }
		.flatMap { (packet, endpoint) in
			packet.publisher.map { (endpoint, $0, $1) }
		}
}
//public func UdpReceiver<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none) -> some Publisher<(Packet, Endpoint), NWError> {
//	UdpStream.Incoming(on: endpoint)
//		.publisher
//		.flatMap { $0 }
//		.compactMap { (data, endpoint) in Packet(rawValue: data).map{($0, endpoint)} }
//}
//public func TcpReceiver<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none, count: Int = 1) -> AsyncFlatMapSequence<AsyncThrowingStream<(TcpStream<Endpoint>, Endpoint), Error>, AsyncMapSequence<AsyncCompactMapSequence<TcpStream<Endpoint>, Packet>, (Packet, Endpoint)>> {
//	TcpStream.Incoming(on: endpoint, count: count, queue: queue).flatMap {(stream, endpoint)in
//		stream.compactMap(Packet.init(rawValue:)).map { ($0, endpoint) }
//	}
//}
public func TcpReceiver<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none, count: Int = 1) -> some Publisher<(Endpoint, String, Array<Argument>), NWError> {
	TcpStream.Incoming(on: endpoint, count: count, queue: queue)
		.flatMap { (stream, endpoint) in stream.compactMap { Packet(rawValue: $0).map { ($0, endpoint) } } }
		.flatMap { (packet, endpoint) in
			packet.publisher.map { (endpoint, $0, $1) }
		}
}
