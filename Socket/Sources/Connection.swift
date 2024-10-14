//
//  Connection.swift
//  
//
//  Created by kotan.kn on 8/4/R6.
//
import struct Foundation.Data
import Network
@preconcurrency import Combine
import Async_
import Synchronization
import os.log
public struct Connection: Sendable {
	@usableFromInline
	let nw: NWConnection
	public let state: CurrentValueSubject<NWConnection.State, Never>
}
extension Connection {
	@inlinable
	init(nw connection: NWConnection, queue: DispatchQueue) {
		nw = connection
		state = .init(connection.state)
		nw.stateUpdateHandler = unsafeBitCast(state.send as (NWConnection.State) -> Void, to: (@Sendable (NWConnection.State) -> Void).self)
		nw.start(queue: queue)
	}
}
extension Connection {
	public init(to endpoint: NWEndpoint, with `protocol`: NWParameters, queue: DispatchQueue = .global()) {
		self.init(nw: .init(to: endpoint, using: `protocol`), queue: queue)
	}
}
extension Connection {
	@discardableResult
	public func send(message data: Data) -> Future<(), NWError> {
		.init {
			let promise = unsafeBitCast($0, to: (@Sendable(Result<(), NWError>) -> Void).self)
			nw.send(content: data, contentContext: .defaultMessage, completion: .contentProcessed {
				promise($0.map(Result.failure) ?? .success(()))
			})
		}
	}
	@discardableResult
	public func send(stream: some Publisher<Data, Never>) -> some Publisher<(), NWError> {
		let broker = PassthroughSubject<(), NWError>()
		let cancel = stream.sink { x in
			nw.send(content: .none, contentContext: .defaultStream, isComplete: true, completion: .idempotent)
			broker.send(completion: .finished)
		} receiveValue: {
			nw.send(content: $0, contentContext: .defaultStream, isComplete: false, completion: .contentProcessed {
				switch $0 {
				case.some(let error):
					broker.send(completion: .failure(error))
				case.none:
					broker.send(())
				}
			})
		}
		return broker.handleEvents(receiveCancel: cancel.cancel)
	}
}
extension Connection {
	public func recv() -> Future<Data, NWError> {
		.init {
			let promise = unsafeBitCast($0, to: (@Sendable(Result<Data, NWError>) -> Void).self)
			nw.receiveMessage {
				promise($3.map(Result.failure) ?? .success($0 ?? .init()))
			}
		}
	}
	public func recv(count: Int) -> some Publisher<Data, NWError> {
		let broker = PassthroughSubject<Data, NWError>()
		let active = Atomic(true)
		@Sendable
		func recv(nw: NWConnection, count: Int) {
			nw.receive(minimumIncompleteLength: 0, maximumLength: count) {
				if let error = $3 {
					broker.send(completion: .failure(error))
				} else if $2 {
					broker.send($0 ?? .init())
					broker.send(completion: .finished)
				} else if active.load(ordering: .acquiring) {
					broker.send($0 ?? .init())
					recv(nw: nw, count: count)
				}
			}
		}
		recv(nw: nw, count: count)
		return broker.handleEvents(receiveCancel: { active.store(false, ordering: .releasing) })
	}
}
extension Connection {
	public static func Incoming(on port: NWEndpoint.Port, with protocol: NWParameters, queue: DispatchQueue = .global()) -> some Publisher<Connection, Error> {
		Result {
			try NWListener(using: `protocol`, on: port)
		}
		.publisher
		.flatMap { listener in
			Deferred {
				let broker = PassthroughSubject<NWConnection, Error>()
				listener.newConnectionHandler = unsafeBitCast(broker.send as (NWConnection) -> Void, to: (@Sendable (NWConnection) -> Void).self)
				defer {
					listener.start(queue: queue)
				}
				return broker.map { Connection(nw: $0, queue: queue) }.handleEvents(receiveCancel: listener.cancel)
			}
		}
		
	}
}
//public struct Connection {
//	@usableFromInline
//	let nw: NWConnection
//	public let state2: CurrentValueSubject<NWConnection.State, Never>
//	public let statePublisher: Publishers.Share<CurrentValueSubject<NWConnection.State, Never>>
//	public let pathPublisher: Publishers.Share<Publishers.Buffer<PassthroughSubject<NWPath, Never>>>
//}
//extension Connection {
//	@inline(__always)
//	@inlinable
//	init(nw connection: NWConnection, queue: DispatchQueue) {
//		let state = CurrentValueSubject<NWConnection.State, Never>(.setup)
//		let path = PassthroughSubject<NWPath, Never>()
//		statePublisher = state.share()
//		pathPublisher = path.buffer(size: 1, prefetch: .keepFull, whenFull: .dropOldest).share()
//		nw = connection
//		state2 = .init(nw.state)
//		nw.stateUpdateHandler = state.send
//		nw.pathUpdateHandler = path.send
//		nw.start(queue: queue)
//	}
//}
//extension Connection {
//	public init(to endpoint: NWEndpoint, by parameter: NWParameters, queue: DispatchQueue = .global()) {
//		self.init(nw: .init(to: endpoint, using: parameter), queue: queue)
//	}
//}
//extension Connection {
//	@inlinable
//	public var status: NWConnection.State {
//		nw.state
//	}
//	@inlinable
//	public var stating: AsyncPublisher<some Publisher<NWConnection.State, Never>> {
//		statePublisher.values
//	}
//}
//extension Connection {
//	@inlinable
//	public var path: Optional<NWPath> {
//		nw.currentPath
//	}
//	@inlinable
//	public var pathing: AsyncPublisher<some Publisher<NWPath, Never>> {
//		pathPublisher.values
//	}
//}
//extension Connection {
//	@discardableResult
//	public func send(message: Data) -> Future<(), NWError> {
//		.init { promise in
//			nw.send(content: message, completion: .contentProcessed {
//				promise($0.map(Result.failure) ?? .success(()))
//			})
//		}
//	}
//	@discardableResult
//	public func send<Stream: AsyncSequence>(stream: Stream) -> Future<(), Error> where Stream.Element == Data {
//		.init { promise in
//			do {
//				for try await data in stream {
//					try await withCheckedThrowingContinuation { handle in
//						nw.send(content: data, contentContext: .defaultStream, isComplete: false, completion: .contentProcessed {
//							handle.resume(with: $0.map(Result.failure) ?? .success(()))
//						})
//					} as ()
//				}
//				try await withCheckedThrowingContinuation { handle in
//					nw.send(content: .none, contentContext: .defaultStream, isComplete: true, completion: .contentProcessed {
//						handle.resume(with: $0.map(Result.failure) ?? .success(()))
//					})
//				} as ()
//				promise(.success(()))
//			} catch {
//				promise(.failure(error))
//			}
//		}
//	}
//	@discardableResult
//	public func send<Failure>(stream: some Publisher<Data, Failure>) -> Future<(), Error> {
//		send(stream: stream.values)
//	}
//}
//extension Connection {
//	public func recv() -> Future<Data, NWError> {
//		.init { promise in
//			nw.receiveMessage {
//				promise($3.map(Result.failure) ?? .success($0 ?? .init()))
//			}
//		}
//	}
//	public func recv(count: Int) -> Future<Data, NWError> {
//		.init { promise in
//			nw.receive(minimumIncompleteLength: 0, maximumLength: count) {
//				promise($3.map(Result.failure) ?? .success($0 ?? .init()))
//			}
//		}
//	}
//}
//extension Connection {
//	public func stream(count: Int) -> some Publisher<Data, NWError> {
//		Deferred<PassthroughSubject<Data, NWError>> {
//			let broker = PassthroughSubject<Data, NWError>()
//			func request() {
//				nw.receive(minimumIncompleteLength: 0, maximumLength: count) {
//					switch ($0, $2, $3) {
//					case(_, _, .some(let error)):
//						broker.send(completion: .failure(error))
//					case(.some(let data), false, .none):
//						broker.send(data)
//						request()
//					case(.some(let data), true, .none):
//						broker.send(data)
//						broker.send(completion: .finished)
//					case(.none, true, .none):
//						broker.send(completion: .finished)
//					case(.none, false, .none):
//						request()
//					}
//				}
//			}
//			return broker
//		}
//	}
//}
//extension Connection {
//	public struct Incoming {
//		@usableFromInline
//		let nw: NWListener
//		public let statePublisher: Publishers.Share<PassthroughSubject<NWListener.State, Never>>
//		public let incomePublisher: Publishers.Share<Publishers.Map<PassthroughSubject<NWConnection, Never>, Connection>>
//	}
//}
//extension Connection.Incoming {
//	public init(on port: NWEndpoint.Port, with protocol: NWParameters, queue: DispatchQueue = .global()) throws {
//		nw = try.init(using: `protocol`, on: port)
//		let state = PassthroughSubject<NWListener.State, Never>()
//		nw.stateUpdateHandler = state.send
//		statePublisher = state.share()
//		let income = PassthroughSubject<NWConnection, Never>()
//		nw.newConnectionHandler = income.send
//		incomePublisher = income.map { Connection(nw: $0, queue: queue) }.share()
//		nw.start(queue: queue)
//	}
//}
//extension Connection.Incoming {
//	@inlinable
//	public var state: NWListener.State {
//		nw.state
//	}
//	@inlinable
//	public var stating: AsyncPublisher<some Publisher<NWListener.State, Never>> {
//		statePublisher.values
//	}
//}
//extension Connection.Incoming: AsyncSequence {
//	public typealias Element = Connection
//	public func makeAsyncIterator() -> AsyncPublisher<some Publisher<Element, Never>>.Iterator {
//		incomePublisher.values.makeAsyncIterator()
//	}
//}
//extension Connection {
//	public static func iv(on port: NWEndpoint.Port, with protocol: NWParameters, queue: DispatchQueue = .global()) -> some Publisher<Connection, Error> {
//		Result {
//			try NWListener(using: `protocol`, on: port)
//		}
//		.publisher
//		.flatMap { listener in
//			Deferred {
//				let vendor = PassthroughSubject<NWConnection, Error>()
//				listener.newConnectionHandler = vendor.send
//				defer {
//					listener.start(queue: queue)
//				}
//				return vendor.map { Self(nw: $0, queue: queue) }.handleEvents(receiveCancel: listener.cancel)
//			}
//		}
//	}
//}
