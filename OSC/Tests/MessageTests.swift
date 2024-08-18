import XCTest
import RegexBuilder
@testable import OSC
final class MessageTests: XCTestCase {
	func testRegexLHS() throws { // Standard style, 1 handler can accept multiple addresses
		switch "/root/abc/foo" as Message {
		case "/root/abc/foo":
			break // write handler here
		default:
			XCTFail()
		}
		for query in ["/root/abc/foo", "/root/abc/bar"] as Array<Message> {
			switch query {
			case /\/root\/ab.\/(?:foo|bar)/:
				break // write handler here
			default:
				XCTFail()
			}
			switch query {
			case try Regex(osc: #"/root/ab?/{foo,bar}"#): // regex literal and regexbuilder are better in performance
				break // write handler here
			default:
				XCTFail()
			}
		}
	}
	func testGlobLHS() throws { // Query style like Unix command, same message can be matched with multiple handlers
		let query = "/root/ab?/{foo,bar}" as Message
		switch query {
		case "/root/abx/foo":
			break
		default:
			XCTFail()
		}
		switch query {
		case "/root/abs/bar":
			break
		default:
			XCTFail()
		}
		switch query {
		case "/root/ab/foo":
			XCTFail()
		default:
			break
		}
		switch query {
		case "/root/ab/bar":
			XCTFail()
		default:
			break
		}
	}
}
