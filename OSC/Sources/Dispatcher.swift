//
//  Router.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import RegexBuilder
import Combine
import Socket
import os.log
public class Dispatcher<Endpoint: IPEndpoint> {
	public typealias Failure = NWError
	@usableFromInline
	let broker: PassthroughSubject<Input, Failure>
	@usableFromInline
	var invoke: Array<((Message, Endpoint)) -> Bool>
	@usableFromInline
	var cancel: Set<AnyCancellable>
	public init() {
		broker = .init()
		invoke = .init()
		cancel = .init()
	}
	deinit {
		cancel.forEach { $0.cancel() }
	}
}
extension Dispatcher {
	@inlinable
	public func add(handler: @escaping (Message, Endpoint) -> Bool) {
		invoke.append(handler)
	}
	@inlinable
	public func add(for receiver: String, execute body: @escaping (String, Arguments, Endpoint) -> Void) {
		invoke.append {
			switch $0 {
			case receiver:
				body($0.address, $0.arguments, $1)
				return true
			default:
				return false
			}
		}
	}
	@inlinable
	public func add<Output>(for pattern: Regex<Output>, execute body: @escaping (Output, Arguments, Endpoint) -> Void) {
		invoke.append {
			switch $0.address.firstMatch(of: pattern) {
			case.some(let match):
				body(match.output, $0.arguments, $1)
				return true
			case.none:
				return false
			}
		}
	}
}
extension Dispatcher: Subscriber {
	public typealias Input = (Message, Endpoint)
	@inlinable
	public func receive(subscription: Subscription) {
		subscription.store(in: &cancel)
		subscription.request(.unlimited)
	}
	@inlinable
	@discardableResult
	public func receive(_ input: Input) -> Subscribers.Demand {
		let result = invoke.first { $0(input) }
		switch result {
		case.some:
			break
		case.none:
			broker.send(input)
		}
		return.unlimited
	}
	@inlinable
	public func receive(completion: Subscribers.Completion<Failure>) {
		broker.send(completion: completion)
	}
}
extension Dispatcher: Publisher {
	public typealias Output = (Message, Endpoint)
	@inlinable
	public func receive<S>(subscriber: S) where S : Subscriber, Output == S.Input, NWError == S.Failure {
		broker.receive(subscriber: subscriber)
	}
}
