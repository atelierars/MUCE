//
//  DispatchQueue+.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
import class Dispatch.DispatchQueue
extension DispatchQueue {
	@inlinable
	public func async<R: Sendable>(execute body: @Sendable @escaping () -> R) async -> R {
		await withUnsafeContinuation { promise in
			async { promise.resume(with: .success(body())) }
		}
	}
	@inlinable
	public func async<Success>(execute body: @Sendable @escaping () -> Result<Success, Never>) async -> Success {
		await withUnsafeContinuation { promise in
			async { promise.resume(with: body()) }
		}
	}
	@inlinable
	public func async<Success, Failure>(execute body: @Sendable @escaping () -> Result<Success, Failure>) async throws -> Success {
		try await withUnsafeThrowingContinuation { promise in
			async { promise.resume(with: body()) }
		}
	}
}
