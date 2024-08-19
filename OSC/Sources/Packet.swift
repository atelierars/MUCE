//
//  Packet.swift
//  
//
//  Created by kotan.kn on 7/31/24.
//
import struct Foundation.Data
@frozen enum Packet {
	case Message(address: String, arguments: Arguments)
	case Bundle(at: TimeTag, packets: Array<Packet>)
}
extension Packet: Equatable {}
extension Packet {
	@inlinable
	init(message: Message) {
		self = .Message(address: message.address, arguments: message.arguments)
	}
	@inlinable
	init(at time: TimeTag = .immediately, messages: some Sequence<Message>) {
		self = .Bundle(at: time, packets: messages.map(Self.init))
	}
}
extension Packet: Sequence {
	@usableFromInline
	struct Iterator: IteratorProtocol {
		var stack: Array<Packet>
		mutating public func next() -> Optional<Message> {
			while let element = stack.popLast() {
				switch element {
				case.Message(let address, let arguments):
					return.some(.init(address, with: arguments))
				case.Bundle(_, let packets):
					stack.append(contentsOf: packets.reversed())
				}
			}
			return.none
		}
	}
	@inlinable
	func makeIterator() -> Iterator {
		Iterator(stack: [self])
	}
}
extension Packet: RawRepresentable {
	@inlinable
	init?(rawValue: Data) {
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
			guard let arguments = Arguments(rawValue: data) else { return nil }
			self = .Message(address: addr, arguments: arguments)
		case.none:
			return nil
		}
	}
	@inlinable
	var rawValue: Data {
		switch self {
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
		case.Message(let address, let arguments):
			address.data(using: .utf8).map {
				$0 + Data(count: 4 - $0.count % 4) +  arguments.rawValue
			} ?? .init()
		}
	}
}
