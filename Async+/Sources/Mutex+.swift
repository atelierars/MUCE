//
//  Mutex+.swift
//  MUCE
//
//  Created by Kota on 10/16/R6.
//
import struct Synchronization.Mutex
extension Mutex where Value: Sendable {
	@discardableResult
	@inlinable @inline(__always)
	public func replace(with value: Value) -> Value {
		withLock { storage in
			defer {
				storage = value
			}
			return storage
		}
	}
}
extension Mutex {
	@discardableResult
	@inlinable @inline(__always)
	func take<Wrapped: Sendable>() -> Optional<Wrapped> where Value == Optional<Wrapped> {
		withLockIfAvailable {
			$0.take()
		}.flatMap(\.self)
	}
}
