//
//  Sender.swift
//  
//
//  Created by kotan.kn on 8/7/R6.
//
import Combine
import Socket
import enum Network.NWError
import var Darwin.errno
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
	func send(packet: Packet, to endpoint: Endpoint) -> Result<(), NWError> {
		socket.flatMap { handle in
			packet.rawValue.withUnsafeBytes { data in
				handle.send(data: data, to: endpoint).flatMap {
					$0 == data.count ? .success(()) : .failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
				}
			}
		}
	}
	@discardableResult
	public func send(message: Message, to endpoint: Endpoint) -> Result<(), NWError> {
		send(packet: .init(message: message), to: endpoint)
	}
	@discardableResult
	public func send(messages: some Sequence<Message>, at time: TimeTag = .immediately, to endpoint: Endpoint) -> Result<(), NWError> {
		send(packet: .init(at: time, messages: messages), to: endpoint)
	}
}
extension UdpSender: Subscriber {
	public typealias Input = (Message, Endpoint)
	public typealias Failure = Never
	public func receive(_ input: (Message, Endpoint)) -> Subscribers.Demand {
		switch send(message: input.0, to: input.1) {
		case.success:
			.unlimited
		case.failure:
			.none
		}
	}
	public func receive(completion: Subscribers.Completion<Never>) {
		
	}
	public func receive(subscription: Subscription) {
		subscription.store(in: &subscribings)
		subscription.request(.unlimited)
	}
}
