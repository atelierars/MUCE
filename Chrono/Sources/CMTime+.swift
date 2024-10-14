//
//  CMTime+.swift
//
//
//  Created by kotan.kn on 8/6/R6.
//
@_exported import struct CoreMedia.CMTime
import typealias CoreMedia.CMTimeValue
import typealias CoreMedia.CMTimeScale
import CoreMedia
import RationalNumbers
import func Integer_.gcd
import func Integer_.abs
import func Integer_.mod
extension CMTime {
	@inlinable
	public init(duration: Duration) {
		let (seconds, attoseconds) = duration.components
		let factor = gcd(1_000_000_000_000_000_000, attoseconds)
		let scale = 1_000_000_000_000_000_000 / factor
		self.init(value: seconds * scale + attoseconds / factor , timescale: .init(scale))
	}
}
extension Duration {
	public init(_ time: CMTime) {
		let integer = time.value / .init(time.timescale)
		let fraction = time.value % .init(time.timescale)
		let factor = gcd(1_000_000_000_000_000_000, CMTimeValue(time.timescale))
		let multiplier = 1_000_000_000_000_000_000 / factor
		let divisor = CMTimeValue(time.timescale) / factor
		self.init(secondsComponent: integer, attosecondsComponent: fraction * multiplier / divisor)
	}
}
extension CMTime {
	@inline(__always)
	@inlinable
	func floor(divisor: CMTime) -> CMTime {
		self - CMTimeModApprox(CMTimeModApprox(self, divisor) + divisor, divisor)
	}
}
extension CMTime {
	@inline(__always)
	@inlinable
	var simplified: CMTime {
		let factor = CMTimeValue(gcd(value.magnitude, .init(timescale.magnitude)))
		return.init(value: value / factor, timescale: .init(.init(timescale) / factor))
	}
}
public func CMTimeDivApprox(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
	assert(CMTimeValue.self == Int64.self)
	assert(CMTimeScale.self == Int32.self)
	let s = Int128(lhs.timescale) * Int128(rhs.value)
	let v = Int128(lhs.value) * Int128(rhs.timescale)
	let f = Integer_.abs(Integer_.gcd(v, s))
	let value = v / f
	let scale = s / f
	let ratio = max(1, (scale)/(1<<31-1))
	return.init(.init(value / ratio), .init(scale / ratio)).simplified
}
public func CMTimeModApprox(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
	assert(CMTimeValue.self == Int64.self)
	assert(CMTimeScale.self == Int32.self)
	let l = Int128(lhs.value) * Int128(rhs.timescale)
	let r = Int128(rhs.value) * Int128(lhs.timescale)
	let s = Int128(rhs.timescale) * Int128(lhs.timescale)
	let v = Integer_.mod(l, r)
	let f = Integer_.abs(Integer_.gcd(v, s))
	let value = v / f
	let scale = s / f
	let ratio = max(1, (scale)/(1<<31-1))
	return.init(.init(value / ratio), .init(scale / ratio)).simplified
}
extension CMTime: @retroactive RationalNumber {
	public typealias IntegerLiteralType = CMTimeValue
	public var magnitude: CMTime {
		CMTimeAbsoluteValue(self)
	}
	public var numerator: CMTimeValue {
		.init(value)
	}
	public var denominator: CMTimeValue {
		.init(timescale)
	}
	public init(numerator: CMTimeValue, denominator: CMTimeValue) {
		self.init(value: .init(numerator), timescale: .init(clamping: denominator))
	}
}
