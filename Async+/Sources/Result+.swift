//
//  Result+.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
extension Result {
	@inlinable
	public func map<R>(_ transform: (Success) async throws -> R) async rethrows -> Result<R, Failure> {
		switch self {
		case.success(let success):
			try await.success(transform(success))
		case.failure(let error):
			.failure(error)
		}
	}
	@inlinable
	public func mapError<R>(_ transform: (Failure) async throws -> R) async rethrows -> Result<Success, R> {
		switch self {
		case.success(let success):
			.success(success)
		case.failure(let error):
			try await.failure(transform(error))
		}
	}
}
extension Result {
	@inlinable
	public func flatMap<R>(_ transform: (Success) async throws -> Result<R, Failure>) async rethrows -> Result<R, Failure> {
		switch self {
		case.success(let success):
			try await transform(success)
		case.failure(let error):
			.failure(error)
		}
	}
	@inlinable
	public func flatMapError<R>(_ transform: (Failure) async throws -> Result<Success, R>) async rethrows -> Result<Success, R> {
		switch self {
		case.success(let success):
			.success(success)
		case.failure(let error):
			try await transform(error)
		}
	}
}
