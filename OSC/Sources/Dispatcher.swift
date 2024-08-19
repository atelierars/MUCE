//
//  Router.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import struct Foundation.UUID
import RegexBuilder
import Combine
import Socket
import os.log
public class Dispatcher<Endpoint: IPEndpoint> {
	public typealias Failure = NWError
	@usableFromInline
	let broker: PassthroughSubject<Input, Failure>
	@usableFromInline
	var invoke: Dictionary<UUID, ((Message, Endpoint)) -> Bool> = [:]
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
	@discardableResult
	public func invoke(handler: @escaping (Message, Endpoint) -> Bool) -> UUID {
		let id = UUID()
		defer {
			invoke.updateValue(handler, forKey: id)
		}
		return id
	}
	@inlinable
	@discardableResult
	public func invoke(for path: String, execute body: @escaping (String, Arguments, Endpoint) -> Void) -> UUID {
		invoke {
			switch $0 {
			case path:
				body(path, $0.arguments, $1)
				return true
			default:
				return false
			}
		}
	}
	@inlinable
	@discardableResult
	public func invoke<Output>(for pattern: Regex<Output>, execute body: @escaping (Output, Arguments, Endpoint) -> Void) -> UUID {
		invoke {
			switch $0.address.firstMatch(of: pattern) {
			case.some(let match):
				body(match.output, $0.arguments, $1)
				return true
			case.none:
				return false
			}
		}
	}
	@inlinable
	@discardableResult
	public func remove(invoke id: UUID) -> Bool {
		invoke.removeValue(forKey: id) != nil
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
	public func receive(completion: Subscribers.Completion<Failure>) {
		broker.send(completion: completion)
		cancel.removeAll()
	}
	@inlinable
	@discardableResult
	public func receive(_ input: Input) -> Subscribers.Demand {
		let result = invoke.values.filter { $0(input) }.isEmpty
		if result {
			broker.send(input)
		}
		return.unlimited
	}
}
extension Dispatcher: Publisher { // Publish not recept messages
	public typealias Output = (Message, Endpoint)
	@inlinable
	public func receive(subscriber: some Subscriber<Output, Failure>) {
		broker.receive(subscriber: subscriber)
	}
}
