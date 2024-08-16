//
//  Router.swift
//
//
//  Created by kotan.kn on 8/4/R6.
//
import RegexBuilder
import Combine
public protocol RouterProtocol {
	func dispatch(packet: Packet)
}
public typealias Router = Array<(String, Optional<Array<Argument>>) -> Bool>
extension Router {
	public mutating func append(starts pattern: some RegexComponent, body: @escaping (String, Array<Argument>) -> Void) {
		append {
			if $0.starts(with: pattern) {
				if let arguments = $1 {
					body($0, arguments)
				}
				return true
			} else {
				return false
			}
		}
	}
	public mutating func append<Output>(for regex: Regex<Output>, body: @escaping (Output, Array<Argument>) -> Void) {
		append {
			if let match = $0.firstMatch(of: regex) {
				if let arguments = $1 {
					body(match.output, arguments)
				}
				return true
			} else {
				return false
			}
		}
	}
	public mutating func remove(for address: String) {
		removeAll {
			$0(address, .none)
		}
	}
}
extension Router: RouterProtocol {
	@inlinable
	public func dispatch(packet: Packet) {
		switch packet {
		case.Message(let address, let arguments):
			_ = firstIndex {
				$0(address, .some(arguments))
			}
		case.Bundle(_, let packets):
			packets.forEach(dispatch(packet:))
		}
	}
}
