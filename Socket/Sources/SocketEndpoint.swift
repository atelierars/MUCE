//
//  SocketEndpoint.swift
//  
//
//  Created by kotan.kn on 8/3/R6.
//
public protocol SocketEndpoint: Sendable & Equatable {
	static var family: Int32 { get }
}
