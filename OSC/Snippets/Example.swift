//
//  View.swift
//
//
//  Created by Kota on 8/16/R6.
//
import SwiftUI
import OSC
@main
struct App: SwiftUI.App {
	var body: some Scene {
		WindowGroup {
			VStack {
				ReceiveView()
				SenderView()
			}
		}
	}
}
struct ReceiveView: View {
	var body: some View {
		Text("Hello")
	}
}
struct SenderView: View {
	var body: some View {
		Text("Hello")
	}
}
