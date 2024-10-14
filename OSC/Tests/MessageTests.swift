import Testing
import RegexBuilder
@testable import OSC
@Suite
struct MessageTests {
	@Test
	func regexLHS() throws {
		switch "/root/abc/foo" as Message {
		case "/root/abc/foo":
			break // write handler here
		default:
			Issue.record()
		}
		for query in ["/root/abc/foo", "/root/abc/bar"] as Array<Message> {
			switch query {
			case /\/root\/ab.\/(?:foo|bar)/:
				break // write handler here
			default:
				Issue.record()
			}
			switch query {
			case try Regex(osc: #"/root/ab?/{foo,bar}"#): // regex literal and regexbuilder are better in performance
				break // write handler here
			default:
				Issue.record()
			}
		}
	}
	@Test
	func globLHS() throws {
		let query = "/root/ab?/{foo,bar}" as Message
		switch query {
		case "/root/abx/foo":
			break
		default:
			Issue.record()
		}
		switch query {
		case "/root/abs/bar":
			break
		default:
			Issue.record()
		}
		switch query {
		case "/root/ab/foo":
			Issue.record()
		default:
			break
		}
		switch query {
		case "/root/ab/bar":
			Issue.record()
		default:
			break
		}
	}
}
