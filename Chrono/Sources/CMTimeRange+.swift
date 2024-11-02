//
//  CMTimeRange+.swift
//  MUCE
//
//  Created by Kota on 11/2/R6.
//
import struct CoreMedia.CMTimeRange
extension CMTimeRange {
	@inlinable @inline(__always)
	public static func~=(lhs: CMTimeRange, rhs: CMTime) -> Bool {
		lhs.containsTime(rhs)
	}
}
