//
//  DispatchQueue+.swift
//  MUCE
//
//  Created by kotan.kn on 8/3/R6.
//
import class Dispatch.DispatchQueue
extension DispatchQueue {
	@inlinable
	public func async<R: Sendable>(execute body: @Sendable @escaping () -> sending R) async -> sending R {
		await withUnsafeContinuation { promise in
			async { promise.resume(with: .success(body())) }
		}
	}
	@inlinable
	public func async<Success>(execute body: @Sendable @escaping () -> sending Result<Success, Never>) async -> sending Success {
		await withUnsafeContinuation { promise in
			async { promise.resume(with: body()) }
		}
	}
	@inlinable
	public func async<Success, Failure>(execute body: @Sendable @escaping () -> sending Result<Success, Failure>) async throws -> sending Success {
		try await withUnsafeThrowingContinuation { promise in
			async { promise.resume(with: body()) }
		}
	}
}
