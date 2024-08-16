//
//  Async+Tests.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import XCTest
import Combine
@testable import Async_
final class AsyncPlusTests: XCTestCase {
	func testAsyncFuture() async throws {
		let random = Int.random(in: -64...64)
		let future = Future<Int, Never> {
			await $0(DispatchQueue.global(qos: .background).async {
				Result<Int, Never>.success(random * random)
			})
		}
		let result = await future.value
		XCTAssertEqual(result, random * random)
	}
	func testResultMap() async throws {
		let random = Int.random(in: -64...64)
		let source = Result<Int, Never>.success(random)
		let result = try await source.map { value in
			await DispatchQueue.global(qos: .default).async {
				value * value
			}
		}.get() as Int
		XCTAssertEqual(result, random * random)
	}
}
