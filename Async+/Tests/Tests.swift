//
//  Async+Tests.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import Testing
import Combine
import Dispatch
@testable import Async_
@Test
func future() async throws {
	let random = Int.random(in: -64...64)
	let future = Future<Int, Never> {
		await $0(DispatchQueue.global(qos: .background).async {
			Result<Int, Never>.success(random * random)
		})
	}
	let result = await future.value
	#expect(result == random * random)
}
@Test
func map() async throws {
	let random = Int.random(in: -64...64)
	let source = Result<Int, Never>.success(random)
	let result = await source.map { value in
		await DispatchQueue.global(qos: .default).async {
			value * value
		}
	}.get() as Int
	#expect(result == random * random)
}
@Test
func timeout() async throws {
	try await withTimeoutTask(for: .milliseconds(100)) {
		try await Task.sleep(for: .milliseconds(10))
	}
	await withKnownIssue {
		try await withTimeoutTask(for: .milliseconds(10)) {
			try await Task.sleep(for: .milliseconds(100))
		}
	}
}
