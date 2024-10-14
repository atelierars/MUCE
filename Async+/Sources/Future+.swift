//
//  Future+.swift
//  MUCE
//
//  Created by kotan.kn on 8/4/R6.
//
import class Combine.Future
extension Future {
	public convenience init(_ attemptToFulfill: @escaping(@escaping @Sendable(Result<Output, Failure>) -> Void) -> Void) {
		self.init { promise in
			attemptToFulfill(unsafeBitCast(promise, to: (@Sendable(Result<Output, Failure>) -> Void).self))
		}
	}
	public convenience init(_ attemptToFulfill: @escaping @Sendable(@Sendable(Result<Output, Failure>) -> Void) async -> Void) {
		self.init { promise in
			Task {
				await attemptToFulfill(promise)
			}
		}
	}
}
