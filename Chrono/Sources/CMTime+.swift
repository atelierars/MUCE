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
	// Use UInt128 in Swift 6
	let timescale = max(lhs.timescale, rhs.timescale)
	let lhs = lhs.convertScale(timescale, method: .roundTowardNegativeInfinity)
	let rhs = rhs.convertScale(timescale, method: .roundTowardNegativeInfinity)
	let v = lhs.value * .init(rhs.timescale)
	let s = rhs.value * .init(lhs.timescale)
	let g = CMTimeValue(gcd(v, s).magnitude)
	return.init(value: v / g, timescale: .init(s / g)).simplified
}
public func CMTimeModApprox(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
	// Use UInt128 in Swift 6
	let timescale = max(lhs.timescale, rhs.timescale)
	let lhs = lhs.convertScale(timescale, method: .roundTowardNegativeInfinity)
	let rhs = rhs.convertScale(timescale, method: .roundTowardNegativeInfinity)
	return.init(value: lhs.value % rhs.value, timescale: timescale).simplified
}
extension CMTime: RationalNumber {
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
