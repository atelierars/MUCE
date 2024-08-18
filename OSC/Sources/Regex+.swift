//
//  Regex+.swift
//
//
//  Created by Kota on 8/17/R6.
//
import RegexBuilder
import Darwin
@usableFromInline
enum Context {
	case none
	case quote
	case brace
	case brack
}
@inlinable
func translate(osc fnmatch: inout Substring, context: Context) -> String {
	switch fnmatch.popFirst() {
	case.some("\\") where context != .quote:
		return "\\" + (fnmatch.popFirst().map(String.init) ?? "")
	case.some("^") where context != .quote:
		return "\\^"
	case.some("$") where context != .quote:
		return "\\$"
	case.some(".") where context != .quote:
		return "\\."
	case.some("+") where context != .quote:
		return "\\+"
	case.some("*") where context != .quote && fnmatch.first == .some("*"):
		defer {
			fnmatch.removeFirst()
		}
		return ".*"
	case.some("*") where context != .quote:
		return "[^/]*"
	case.some("?") where context != .quote:
		return "[^/]"
	case.some("\"") where context != .quote:
		var result = ""
		repeat {
			switch fnmatch.first {
			case.some("\""):
				defer {
					fnmatch.removeFirst()
				}
				return result
			case.none:
				return "\\\"" + result
			default:
				result.append(translate(osc: &fnmatch, context: .quote))
			}
		} while true
	case.some("\""):
		return "\\\""
	case.some("!") where context == .brack:
		return "^"
	case.some("-") where context != .brack:
		return "\\-"
	case.some("[") where context != .quote:
		var result = ""
		repeat {
			switch fnmatch.first {
			case.some("]"):
				defer {
					fnmatch.removeFirst()
				}
				return "[" + result + "]"
			case.none:
				return "\\[" + result
			default:
				result.append(translate(osc: &fnmatch, context: .brack))
			}
		} while true
	case.some("]") where context != .quote:
		return "\\]"
	case.some(",") where context == .brace:
		return "|"
	case.some("{") where context != .quote:
		var result = ""
		repeat {
			switch fnmatch.first {
			case.some("}"):
				defer {
					fnmatch.removeFirst()
				}
				return "(?s:" + result + ")"
			case.none:
				return "\\{" + result
			default:
				result.append(translate(osc: &fnmatch, context: .brace))
			}
		} while true
	case.some("}") where context != .quote:
		return "\\}"
	case.some("("):
		return "\\("
	case.some(")"):
		return "\\)"
	case.some(let value):
		return.init(value)
	case.none:
		return ""
	}
}
@inlinable // like fnmatch.translate
func translate(osc fnmatch: some StringProtocol) -> String {
	"^" + sequence(state: Substring(fnmatch)) {
		$0.isEmpty ? .none : .some(translate(osc: &$0, context: .none))
	}.joined() + "$"
}
extension Regex where RegexOutput == AnyRegexOutput {
	@inlinable
	public init(osc pattern: some StringProtocol) throws {
		try self.init(translate(osc: pattern))
	}
}
