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
	var cancellable: Optional<AnyCancellable> = .none
	@Published var description: String = ""
	init(port: UInt16) {
		cancellable = OSC.UdpReceiver(on: IPv4Endpoint(addr: .loopback, port: .init(integerLiteral: port))).sink(receiveCompletion: { complete in
			
		}, receiveValue: { (endpoint, message, options) in
			DispatchQueue.main.sync { [weak self] in
				guard let self else { return }
				description = [message, options.map(String.init).joined(separator: ", "), "from", endpoint.description].joined(separator: " ")
				objectWillChange.send()
			}
		})
	}
	deinit {
		cancellable?.cancel()
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
	@State var message: String = "/address"
	@State var argument: Int32 = 0
	func send() {
		guard let target = IPv4Address(host) else { return }
		sender.send(message: message, with: [.init(argument)], to: .init(addr: target, port: NWEndpoint.Port(integerLiteral: port)))
	}
	var body: some View {
		VStack {
			HStack {
				TextField("Host", text: $host)
				TextField("Port", value: $port, format: .number)
			}
			HStack {
				TextField("Address", text: $message)
				TextField("Argument", value: $argument, format: .number)
			}
			// Push button to send message and integer argument to remote osc receiver
			Button("Send", action: send)
		}
		.padding()
	}
}
