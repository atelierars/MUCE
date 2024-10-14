//
//  CMTime+.swift
//
//
//  Created by kotan.kn on 8/6/R6.
//
@_exported import struct CoreMedia.CMTime
import typealias CoreMedia.CMTimeValue
import typealias CoreMedia.CMTimeScale
import struct CoreMedia.CMTime
import func CoreMedia.CMTimeMultiply
import func CoreMedia.CMTimeAbsoluteValue
import RationalNumbers
import func Integer_.gcd
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
	@inlinable
	@inline(__always)
	func quantise(by period: CMTime, rounding toward: RoundingToward = .zero) -> CMTime {
		let n = Int128(value) * Int128(period.timescale)
		let d = Int128(timescale) * Int128(period.value)
		switch toward {
		case.nearest:
			let r = n % d + d / 2 + d
			let p = n - r % d + d / 2
			return CMTimeMultiply(period, multiplier: .init(p / d))
		case.infinite:
			let r = n % d
			let q = n - ( d + r ) % d
			let p = n + ( d - r ) % d
			return CMTimeMultiply(period, multiplier: .init(p / d + q / d - n / d))
		case.negative:
			let q = n - ( n % d + d ) % d
			return CMTimeMultiply(period, multiplier: .init(q / d))
		case.positive:
			let p = n + ( d - n % d ) % d
			return CMTimeMultiply(period, multiplier: .init(p / d))
		case.zero:
			return CMTimeMultiply(period, multiplier: .init(n / d))
		}
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
	let n = Int128(lhs.value) * Int128(rhs.timescale)
	let d = Int128(lhs.timescale) * Int128(rhs.value)
	let f = gcd(n, d)
	let value = n / f
	let scale = d / f
	let ratio = max(1, (scale)/(1<<30))
	return.init(value: .init(value / ratio), timescale: .init(scale / ratio))
}
public func CMTimeModApprox(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
	assert(CMTimeValue.self == Int64.self)
	assert(CMTimeScale.self == Int32.self)
	let l = Int128(lhs.value) * Int128(rhs.timescale)
	let r = Int128(lhs.timescale) * Int128(rhs.value)
	let n = l % r
	let d = Int128(lhs.timescale) * Int128(rhs.timescale)
	let f = gcd(n, d)
	let value = n / f
	let scale = d / f
	let ratio = max(1, (scale)/(1<<30))
	return.init(value: .init(value / ratio), timescale: .init(scale / ratio))
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
