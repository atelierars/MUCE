//
//  Future+.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import class Combine.Future
extension Future {
	public convenience init(_ attemptToFulfill: @escaping ((Result<Output, Failure>) -> Void) async -> Void) {
		self.init { promise in
			Task {
				await attemptToFulfill(promise)
			}
		}
	}
}
