//
//  Regex+.swift
//
//
//  Created by Kota on 8/17/R6.
//
import RegexBuilder
extension Regex where RegexOutput == AnyRegexOutput {
	@inlinable
	public init(glob pattern: some StringProtocol) throws {
		try self.init(("^" + sequence(state: pattern.reversed()) {
			while let char = $0.popLast() {
				switch char {
				case "?":
					return.some("[^/]?" as String)
				case "*" where $0.last == .some("*"):
					return.some(".*")
				case "*":
					return.some("[^/]*")
				case "{":
					var segment = ""
					var escape = false
					repeat {
						switch $0.popLast() {
						case.some("\""):
							escape.toggle()
						case.some("}"):
							return.some("(" + segment + ")")
						case.some(",") where !escape:
							segment.append("|")
						case.some(let char):
							segment.append(char)
						case.none:
							return.some(segment)
						}
					} while !$0.isEmpty
				case "[":
					var segment = ""
					var escape = false
					repeat {
						switch $0.popLast() {
						case.some("\""):
							escape.toggle()
						case.some("]"):
							return.some("[" + segment + "]")
						case.some("!") where !escape:
							segment.append("^")
						case.some(let char):
							segment.append(char)
						case.none:
							return.some(segment)
						}
					} while !$0.isEmpty
				case let value:
					return.some(String(value))
				}
			}
			return.none
		}.joined() + "$"))
	}
}
