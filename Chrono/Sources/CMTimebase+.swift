//
//  CMTimebase+.swift
//  
//
//  Created by kotan.kn on 8/8/R6.
//
import class CoreMedia.CMTimebase
import struct CoreMedia.CMTime
extension CMTimebase {
	@inlinable
	func convert(reference time: CMTime) -> CMTime {
		source.convertTime(time, to: self)
	}
}
extension CMTimebase: Synchronisable {
	@inline(__always)
	@inlinable
	public var sign: CMTime {
		convert(reference: .zero)
	}
	@inline(__always)
	@inlinable
	public var base: CMTime {
		source.time
	}
	@inline(__always)
	@inlinable
	public func set(rate: Float64) throws {
		try setRate(rate)
	}
	@inline(__always)
	@inlinable
	public func set(rate: Float64, time anchor: CMTime, from reference: CMTime) throws {
		try setRateAndAnchorTime(rate: rate, anchorTime: anchor, referenceTime: reference)
	}
}
