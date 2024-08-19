//
//  Example.swift
//
//
//  Created by kotan.kn on 8/16/R6.
//
import Combine
import Network
import SwiftUI
import OSC
final class Receiver: ObservableObject {
	var dispatcher: Dispatcher<IPv4Endpoint> = .init()
	@Published var description: String = ""
	init(port: UInt16) {
		// accept any message starts with '/', capture target, specified by Regex literal
		dispatcher.add(for: /\/(?<root>.*)/) { [weak self] address, arguments, endpoint in
			guard let self else { return }
			description = [String(address.root), arguments.description, "from", endpoint.description].joined(separator: " ")
			objectWillChange.send()
		}
		/*
		 Single dispatcher can route multiple address
		dispatcher.add(for: "/address/sub1") { [weak self] address, arguments, endpoint in
			guard let self else { return }
			description = [address, "from", endpoint.description].joined(separator: " ")
			objectWillChange.send()
		}
		 Entry dispatcher with regex literal, RegexBuilder object and OSC pattern matcher
		dispatcher.add(for: /address/sub?/) { [weak self] address, arguments, endpoint in
			guard let self else { return }
			description = [address, "from", endpoint.description].joined(separator: " ")
			objectWillChange.send()
		}
		dispatcher.add(for: try!Regex(osc: "/root/sub?/{foo,bar}")) { [weak self] address, arguments, endpoint in
			guard let self else { return }
			description = [address.compactMap { $0.substring }.joined(), "from", endpoint.description].joined(separator: " ")
			objectWillChange.send()
		}
		 */
		// subscribe publisher
		OSC.UdpReceiver(on: IPv4Endpoint(addr: .loopback, port: .init(integerLiteral: port)))
			.receive(on: RunLoop.main)
			.receive(subscriber: dispatcher)
		/*
		 Single dispatcher can accept multiple receiver
		OSC.UdpReceiver(on: IPv4Endpoint(addr: .loopback, port: .init(integerLiteral: 16384)))
			.receive(on: RunLoop.main)
			.receive(subscriber: dispatcher)
		 */
		
	}
}
@main
struct App: SwiftUI.App {
	@State var recvPort: UInt16 = 16384
	@State var text: String = ""
	let portFormatter: NumberFormatter
	init() {
		portFormatter = .init()
		portFormatter.minimum = .init(value: UInt16.min)
		portFormatter.maximum = .init(value: UInt16.max)
	}
	var body: some Scene {
		WindowGroup {
			VStack {
				HStack {
					Text("Receive via")
					TextField("Port", value: $recvPort, formatter: portFormatter)
				}
				HStack {
					Text("Received message:")
				}
				ReceiveView(port: recvPort)
				SenderView()
			}.padding()
		}
	}
}
struct ReceiveView: View {
	@ObservedObject var receiver: Receiver
	init(port: UInt16) {
		receiver = .init(port: port)
	}
	var body: some View {
		Text(receiver.description)
	}
}
struct SenderView: View {
	let sender = OSC.UdpSender<IPv4Endpoint>()
	@State var host: String = "127.0.0.1"
	@State var port: UInt16 = 16384
	@State var address: String = "/address"
	@State var argument: Int32 = 1
	func send() {
		guard let target = IPv4Address(host) else { return }
		var message = Message(address)
		message.append(argument)
		/*
		 A message can have more arguments
		 message.append(1.0 as Float32)
		 message.append("string")
		 message.append(Data())
		 */
		sender.send(message: message, to: .init(addr: target, port: NWEndpoint.Port(integerLiteral: port)))
	}
	var body: some View {
		VStack {
			HStack {
				TextField("Host", text: $host)
				TextField("Port", value: $port, format: .number)
			}
			HStack {
				TextField("Address", text: $address)
				TextField("Argument", value: $argument, format: .number)
			}
			// Push button to send message and integer argument to remote osc receiver
			Button("Send", action: send)
		}
		.padding()
	}
}
