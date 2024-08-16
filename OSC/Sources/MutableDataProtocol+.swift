//
//  MutableDataProtocol+.swift
//  
//
//  Created by kotan.kn on 8/6/R6.
//
import protocol Foundation.MutableDataProtocol
extension MutableDataProtocol {
	@inlinable
	mutating func popElement<T>() -> Optional<T> {
		guard MemoryLayout<T>.size <= count else { return nil }
		defer {
			removeFirst(MemoryLayout<T>.stride)
		}
		return withUnsafeTemporaryAllocation(of: T.self, capacity: 1) {
			copyBytes(to: $0)
			return $0.first
		}
	}
	@inlinable
	mutating func popCString() -> Optional<String> {
		.init(bytes: pop { $0 != .zero }, encoding: .utf8)
	}
	@inlinable
	@discardableResult
	mutating func pop(count: Int) -> SubSequence {
		let slice = prefix(count)
		defer {
			removeFirst(slice.count)
		}
		return slice
	}
	@inlinable
	@discardableResult
	mutating func pop(while closure: (UInt8) -> Bool) -> SubSequence {
		let slice = prefix(while: closure)
		defer {
			removeFirst(slice.count)
		}
		return slice
	}
}
