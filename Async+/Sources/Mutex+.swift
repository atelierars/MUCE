//
//  Mutex+.swift
//  MUCE
//
//  Created by Kota on 10/16/R6.
//
import struct Synchronization.Mutex
extension Mutex where Value: Sendable {
	@discardableResult
	@inlinable
	public func replace(with value: Value) -> Value {
		withLock { storage in
			defer {
				storage = value
			}
			return storage
		}
	}
}
