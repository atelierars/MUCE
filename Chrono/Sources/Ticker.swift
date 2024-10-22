//
//  Ticker.swift
//
//
//  Created by kotan.kn on 8/7/R6.
//
import protocol Combine.Publisher
import class Combine.PassthroughSubject
import class Combine.CurrentValueSubject
import class Combine.Future
import class Combine.AnyCancellable
import struct Combine.Deferred
import protocol CoreMedia.CMSyncProtocol
import class CoreMedia.CMClock
import class CoreMedia.CMTimebase
import struct CoreMedia.CMTime
import func CoreMedia.CMTimeMultiply
import class Dispatch.DispatchSource
import class Dispatch.DispatchQueue
import CoreMedia
public struct Ticker: @unchecked Sendable {
	@usableFromInline
	let handle: CMTimebase
	@usableFromInline
	let vendor: PassthroughSubject<CMTime, Never>
	@usableFromInline
	let cancel: Optional<AnyCancellable>
}
extension Ticker {
	public init(clock: CMClock = .hostTimeClock) throws {
		handle = try.init(sourceClock: clock)
		vendor = .init()
		cancel = .none
	}
	public init(timebase: CMTimebase) throws {
		handle = try.init(sourceTimebase: timebase)
		vendor = .init()
		cancel = .none
	}
	public init(parent ticker: Ticker) throws {
		handle = try.init(sourceTimebase: ticker.handle)
		vendor = .init()
		cancel = .some(ticker.vendor.map(handle.convert(reference:)).sink(receiveValue: vendor.send))
	}
}
extension Ticker {
	public func delay(after latency: CMTime, on queue: Optional<DispatchQueue> = .none) -> some Publisher<CMTime, Error> {
		let source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
		return Future { promise in
			do {
				source.setEventHandler {
					let moment = handle.time
					let elapse = moment.quantise(by: latency, rounding: .negative)
					promise(.success(elapse))
				}
				source.resume()
				let moment = handle.time
				let elapse = moment.quantise(by: latency, rounding: .negative)
				try handle.addTimer(source)
				try handle.setTimerNextFireTime(source, fireTime: elapse + latency)
			} catch {
				promise(.failure(error))
			}
		}.handleEvents(receiveCompletion: { _ in
			try?handle.removeTimer(source)
		}, receiveCancel: {
			try?handle.removeTimer(source)
		})
	}
}
extension Ticker {
	public func timerReusable(for period: CMTime, on queue: Optional<DispatchQueue> = .none) -> some Publisher<CMTime, Error> {
		Deferred {
			timer(for: period, on: queue)
		}
	}
	public func timer(for period: CMTime, on queue: Optional<DispatchQueue> = .none) -> some Publisher<CMTime, Error> {
		let broker = PassthroughSubject<CMTime, Error>()
		let source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
		let cancel = vendor.sink { moment in
			do {
				let elapse = moment.quantise(by: period, rounding: .negative)
				try handle.addTimer(source)
				try handle.setTimerNextFireTime(source, fireTime: elapse + period)
			} catch {
				
			}
		}
		source.setRegistrationHandler {
			do {
				let moment = handle.time
				let elapse = moment.quantise(by: period, rounding: .negative)
				try handle.addTimer(source)
				try handle.setTimerNextFireTime(source, fireTime: elapse + period)
			} catch {
				broker.send(completion: .failure(error))
			}
		}
		source.setEventHandler {
			do {
				let moment = handle.time
				let elapse = moment.quantise(by: period, rounding: .negative)
				try handle.addTimer(source)
				try handle.setTimerNextFireTime(source, fireTime: elapse + period)
				broker.send(elapse)
			} catch {
				broker.send(completion: .failure(error))
			}
		}
		source.setCancelHandler {
			defer {
				cancel.cancel()
				source.setRegistrationHandler(handler: .none)
				source.setEventHandler(handler: .none)
				source.setCancelHandler(handler: .none)
			}
			do {
				try handle.removeTimer(source)
				broker.send(completion: .finished)
			} catch {
				broker.send(completion: .failure(error))
			}
		}
		defer {
			source.resume()
		}
		return broker.handleEvents(receiveCancel: source.cancel)
	}
}
extension Ticker: CMSyncProtocol {
	@inlinable
	public var rate: Float64 {
		handle.rate
	}
	@inlinable
	public var time: CMTime {
		handle.time
	}
	@inlinable
	public func convertTime<T>(_ time: CMTime, to clockOrTimebase: T) -> CMTime where T : CMSyncProtocol {
		handle.convertTime(time, to: clockOrTimebase)
	}
	@inlinable
	public func mightDrift<T>(relativeTo clockOrTimebase: T) -> Bool where T : CMSyncProtocol {
		handle.mightDrift(relativeTo: clockOrTimebase)
	}
	@inlinable
	public func rate<T>(relativeTo clockOrTimebase: T) -> Float64 where T : CMSyncProtocol {
		handle.rate(relativeTo: clockOrTimebase)
	}
	@inlinable
	public func rateAndAnchorTime<T>(relativeTo clockOrTimebase: T) throws -> (rate: Float64, anchorTime: CMTime, referenceTime: CMTime) where T : CMSyncProtocol {
		try handle.rateAndAnchorTime(relativeTo: clockOrTimebase)
	}
}
extension Ticker {
	@inlinable
	public func set(rate: Float64) throws {
		try handle.setRate(rate)
	}
	@inlinable
	public func set(time anchor: CMTime) throws {
		try handle.setTime(anchor)
		vendor.send(anchor)
	}
	@inlinable
	public func set(time anchor: CMTime, at reference: CMTime) throws {
		try handle.setAnchorTime(anchor, referenceTime: reference)
		vendor.send(anchor)
	}
	@inlinable
	public func set(rate: Float64, time anchor: CMTime, from reference: CMTime) throws {
		try handle.setRateAndAnchorTime(rate: rate, anchorTime: anchor, referenceTime: reference)
		vendor.send(anchor)
	}
}
extension Ticker: Synchronisable {
	@inlinable
	public var sign: CMTime {
		handle.sign
	}
	@inlinable
	public var base: CMTime {
		handle.source.time
	}
}
