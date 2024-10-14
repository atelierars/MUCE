//
//  Synchronisable.swift
//
//
//  Created by kotan.kn on 8/9/R6.
//
import class Dispatch.DispatchQueue
import protocol Combine.Publisher
import class Combine.PassthroughSubject
import enum Network.NWError
import protocol Socket.IPEndpoint
import struct Socket.UdpStream
import CoreMedia
import os.log
public protocol SynchroniseSource {
	var sign: CMTime { get }
	var base: CMTime { get }
	var time: CMTime { get }
	var rate: Float64 { get }
}
public protocol Synchronisable: SynchroniseSource {
	func set(rate: Float64) throws
	func set(rate: Float64, time anchor: CMTime, from reference: CMTime) throws
}
extension SynchroniseSource {
	public func udpSynchroniser<Endpoint: IPEndpoint>(on endpoint: Endpoint, queue: Optional<DispatchQueue> = .none) -> some Publisher<Endpoint, NWError>  {
		UdpStream<Endpoint>.Incoming(on: endpoint, queue: queue)
			.publisher
			.flatMap { stream in
				let broker = PassthroughSubject<Endpoint, NWError>()
				let cancel = stream.sink(receiveCompletion: broker.send(completion:)) {(packet, client)in
					let time = time
					let sign = sign
					var data = packet.withUnsafeBytes { $0.withMemoryRebound(to: CMTime.self, Array.init) }
					switch data.count {
					case 2:
						data.append(sign)
						data.append(time)
						data.withUnsafeBytes {
							switch stream.send(data: $0, to: client) {
							case.success($0.count):
								broker.send(endpoint)
							case.success:
								break
							case.failure(let error):
								broker.send(completion: .failure(error))
							}
						}
					default:
						break
					}
				}
				return broker.handleEvents(receiveCancel: cancel.cancel)
			}
	}
}
extension Synchronisable {
	public func udpSynchroniser<Endpoint: IPEndpoint>(to endpoint: Endpoint, queue: Optional<DispatchQueue> = .none, interval: DispatchTimeInterval = .seconds(1)) -> some Publisher<CMTime, Error> {
		UdpStream<Endpoint>.Any(on: queue)
			.mapError { $0 }
			.publisher
			.flatMap { stream in
				let system = OSLog(subsystem: String(reflecting: self), category: .pointsOfInterest)
				var anchor = (p: CMTime.invalid, t: CMTime.invalid, τ: CMTime.invalid, ε: CMTime.invalid)
				let broker = PassthroughSubject<CMTime, Error>()
				let source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
				let cancel = stream.mapError { $0 }.sink(receiveCompletion: broker.send(completion:)) {(packet, sender)in
					let time = time
					let recv = base
					let sign = sign
					let data = packet.withUnsafeBytes { $0.withMemoryRebound(to: CMTime.self, Array.init) }
					switch data.count {
					case 4:
						let (σ, send, p, τ) = data.withUnsafeBytes { $0.load(as: (CMTime, CMTime, CMTime, CMTime).self) }
						let t = CMTimeMultiplyByRatio(recv + send, multiplier: 1, divisor: 2)
						let ε = CMTimeMultiplyByRatio(recv - send, multiplier: 1, divisor: 2)
						let χ = time - CMTimeMultiplyByFloat64(ε, multiplier: rate)
						if σ != sign {
							return
						} else if p != anchor.p {
							anchor.p = p
							anchor.ε = .positiveInfinity
						} else if ε < anchor.ε {
							anchor.τ = τ
							anchor.t = t
							anchor.ε = ε
						} else if ε < CMTimeAbsoluteValue(τ - χ) {
							let dτ = τ - anchor.τ
							let dt = t - anchor.t
							let rate = dτ.seconds / dt.seconds
							do {
								try set(rate: rate, time: τ, from: t)
								os_log(.debug, log: system, "absolute adjust %lf, peer: %lf, self: %lf", rate, τ.seconds, χ.seconds)
								broker.send(τ)
							} catch {
								broker.send(completion: .failure(error))
							}
						} else {
							let Δτ = τ - χ
							let dτ = τ - anchor.τ
							let dt = t - anchor.t
							let rate = dτ.seconds / dt.seconds + Δτ.seconds * anchor.ε.seconds / ε.seconds
							do {
								try set(rate: rate)
								os_log(.debug, log: system, "relative adjust %lf, peer: %lf, self: %lf", rate, τ.seconds, χ.seconds)
							} catch {
								broker.send(completion: .failure(error))
							}
						}
					default:
						break
					}
				}
				source.setEventHandler {
					withUnsafeBytes(of: (sign, base)) {
						switch stream.send(data: $0, to: endpoint) {
						case.success($0.count):
							break
						case.success:
							break
						case.failure(let error):
							broker.send(completion: .failure(error))
						}
					}
				}
				source.setCancelHandler {
					cancel.cancel()
					source.setEventHandler(handler: .none)
					source.setCancelHandler(handler: .none)
				}
				source.schedule(deadline: .now(), repeating: interval)
				defer {
					source.resume()
				}
				return broker.handleEvents(receiveCancel: source.cancel)
			}
	}
}
