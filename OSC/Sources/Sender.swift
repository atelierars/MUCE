//
//  Sender.swift
//  
//
//  Created by kotan.kn on 8/7/R6.
//
import Combine
import Socket
import enum Network.NWError
public final class UdpSender<Endpoint: IPEndpoint> {
	let socket: Result<UdpSocket<Endpoint>, NWError>
	var subscribings: Set<AnyCancellable>
	public init() {
		socket = UdpSocket<Endpoint>.new
		subscribings = .init()
	}
	deinit {
		subscribings.forEach { $0.cancel() }
	}
}
extension UdpSender {
	@discardableResult
	public func send(packet: Packet, to endpoint: Endpoint) -> Result<Int, NWError> {
		socket.flatMap { handle in
			packet.rawValue.withUnsafeBytes {
				handle.send(data: $0, to: endpoint)
			}
		}
	}
	@discardableResult
	public func send(message address: String, with arguments: Array<Argument> = [], to endpoint: Endpoint) -> Result<Int, NWError> {
		send(packet: .Message(address: address, arguments: arguments), to: endpoint)
	}
	@discardableResult
	public func send(messages: Array<(String, Array<Argument>)>, to endpoint: Endpoint) -> Result<Int, NWError> {
		send(packet: .Bundle(at: .immediately, packets: messages.map(Packet.Message)), to: endpoint)
	}
}
extension UdpSender: Subscriber {
	public typealias Input = (Packet, Endpoint)
	public typealias Failure = Never
	public func receive(_ input: (Packet, Endpoint)) -> Subscribers.Demand {
		send(packet: input.0, to: input.1)
		return.unlimited
	}
	public func receive(completion: Subscribers.Completion<Never>) {
		
	}
	public func receive(subscription: Subscription) {
		subscription.store(in: &subscribings)
		subscription.request(.unlimited)
	}
}
