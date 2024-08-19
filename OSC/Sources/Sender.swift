//
//  Sender.swift
//  
//
//  Created by kotan.kn on 8/7/R6.
//
import protocol Combine.Publisher
import protocol Combine.Subscriber
import protocol Combine.Subscription
import enum Combine.Subscribers
import class Combine.AnyCancellable
import protocol Socket.IPEndpoint
import class Socket.UdpSocket
import enum Network.NWError
import var Darwin.errno
public final class UdpSender<Endpoint: IPEndpoint> {
	let socket: Result<UdpSocket<Endpoint>, NWError>
	var subscriptions: Set<AnyCancellable>
	public init() {
		socket = UdpSocket<Endpoint>.new
		subscriptions = .init()
	}
	deinit {
		subscriptions.forEach { $0.cancel() }
	}
}
extension UdpSender {
	@discardableResult
	func send(packet: Packet, to endpoint: Endpoint) -> Result<(), NWError> {
		socket.flatMap { handle in
			packet.rawValue.withUnsafeBytes {
				switch handle.send(data: $0, to: endpoint) {
				case.success($0.count):
					.success(())
				case.success:
					.failure(.posix(.init(rawValue: errno).unsafelyUnwrapped))
				case.failure(let failure):
					.failure(failure)
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
	public func receive(_ input: Input) -> Subscribers.Demand {
		switch send(message: input.0, to: input.1) {
		case.success:
			.unlimited
		case.failure:
			.none
		}
	}
	public func receive(completion: Subscribers.Completion<Never>) {
		subscriptions.removeAll()
	}
	public func receive(subscription: Subscription) {
		subscription.store(in: &subscriptions)
		subscription.request(.unlimited)
	}
}
