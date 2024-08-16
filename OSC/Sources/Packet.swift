//
//  Packet.swift
//  
//
//  Created by kotan.kn on 7/31/24.
//
import struct Foundation.Data
import RegexBuilder
public enum Packet {
	case Message(address: String, arguments: Array<Argument>)
	case Bundle(at: TimeTag, packets: Array<Packet>)
}
extension Packet {
	public init(address: String, arguments: Array<Argument> = .init()) {
		self = .Message(address: address, arguments: arguments)
	}
	public init(at time: TimeTag = .immediately, messages: Array<(String, Array<Argument>)>) {
		self = .Bundle(at: time, packets: messages.map { Packet.Message(address: $0, arguments: $1) })
	}
	public init(at time: TimeTag = .immediately, packets: Array<Self>) {
		self = .Bundle(at: time, packets: packets)
	}
}
extension Packet: Equatable {
	
}
extension Packet: CustomStringConvertible {
	@inlinable
	public var description: String {
		switch self {
		case.Message(let address, let arguments):
			"\(address) \(arguments)"
		case.Bundle(let time, let packets):
			"\(time) \(packets)"
		}
	}
}
extension Packet: Sequence {
	public struct Iterator: IteratorProtocol {
		var stack: Array<Packet>
		mutating public func next() -> Optional<(String, Array<Argument>)> {
			while let element = stack.popLast() {
				switch element {
				case.Message(let address, let arguments):
					return.some((address, arguments))
				case.Bundle(_, let packets):
					stack.append(contentsOf: packets.reversed())
				}
			}
			return.none
		}
	}
	public func makeIterator() -> Iterator {
		Iterator(stack: [self])
	}
}
extension Packet {
	@inlinable
	public var isStandard: Bool {
		switch self {
		case.Message(let address, let arguments):
			address.starts(with: "/") && arguments.allSatisfy { $0.isStandard }
		case.Bundle(_, let arguments):
			!arguments.isEmpty
		}
	}
}
extension Packet: RawRepresentable {
	public init?(rawValue: Data) {
		var data = rawValue
		let type = data.pop { $0 != .zero }
		switch String(data: type, encoding: .utf8) {
		case.some("#bundle"):
			data.pop(count: 4 - type.count % 4)
			guard let time = data.popElement().map(UInt64.init(bigEndian:)).map(TimeTag.init(rawValue:)) else { return nil }
			var packets = Array<Packet>()
			while let count = data.popElement().map(UInt32.init(bigEndian:)), 0 < count {
				let segment = data.pop(count: .init(count))
				guard segment.count == .init(count), let packet = Self(rawValue: segment) else { return nil }
				data.pop(count: 3 - (segment.count + 3) % 4)
				packets.append(packet)
			}
			self = .Bundle(at: time, packets: packets)
		case.some(let addr):
			data.pop(count: 4 - type.count % 4)
			var tags = data.pop { $0 != .zero }
			data.pop(count: 4 - tags.count % 4)
			guard tags.popFirst().map(Unicode.Scalar.init).map(Character.init) == .some(",") else { return nil }
			var args = Array<Argument>()
			while !tags.isEmpty {
				guard let value = Argument(decode: &tags, with: &data) else { return nil }
				args.append(value)
			}
			self = .Message(address: addr, arguments: args)
		case.none:
			return nil
		}
	}
	public var rawValue: Data {
		switch self {
		case.Message(let address, let arguments):
			address.replacingOccurrences(of: "\0", with: "").data(using: .utf8).map { addr in
				var head = Data()
				var body = Data()
				head.append(("," as Character).asciiValue.unsafelyUnwrapped)
				arguments.forEach {
					$0.encode(into: &head, with: &body)
				}
				return
					addr + Data(count: 4 - addr.count % 4) +
					head + Data(count: 4 - head.count % 4) +
					body + Data(count: 3 - ( body.count + 3 ) % 4)
			} ?? .init()
		case.Bundle(let time, let packets):
			"#bundle".data(using: .utf8).map {
				var data = $0
				data.append(0)
				withUnsafeBytes(of: time.rawValue.bigEndian) {
					data.append(contentsOf: $0)
				}
				assert(data.count == 16)
				packets.forEach {
					let packet = $0.rawValue
					assert(packet.count % 4 == 0)
					withUnsafeBytes(of: UInt32(packet.count).bigEndian) {
						data.append(contentsOf: $0)
					}
					data.append(packet)
				}
				return data
			} ?? .init()
		}
	}
}
