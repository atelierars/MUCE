//
//  Timeout.swift
//  MUCE
//
//  Created by Kota on 10/14/R6.
//
@usableFromInline
enum Error: Swift.Error {
	case timedOut
}
@inlinable
public func withTimeoutTask<R: Sendable>(for duration: Duration, function: String = #function,
										 _ body: @escaping @Sendable () async throws -> sending R) async throws -> sending R {
	try await withThrowingTaskGroup(of: R.self) { group in
		group.addTask {
			try await Task.sleep(for: duration)
			throw Error.timedOut
		}
		group.addTask(operation: body)
		return try await group.next().unsafelyUnwrapped
	}
}
