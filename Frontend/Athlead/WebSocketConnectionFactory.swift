//
//  WebSocketConnectionFactory.swift
//  Athlead
//
//  Created by Wichmann, Jan on 08.01.25.
//

import Foundation

/// A simple factory protocol for creating concrete instances of ``WebSocketConnection``.
public protocol WebSocketConnectionFactory {
    func open<Incoming: Decodable & Sendable>(url: URL) -> WebSocketConnection<Incoming>
}

/// A default implementation of ``WebSocketConnectionFactory``.
public final class DefaultWebSocketConnectionFactory: Sendable {
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    /// Initialise a new instance of ``WebSocketConnectionFactory``.
    ///
    /// - Parameters:
    ///   - urlSession: URLSession used for opening WebSockets.
    ///   - encoder: JSONEncoder used to encode outgoing message bodies.
    ///   - decoder: JSONDecoder used to decode incoming message bodies.
    public init(
        urlSession: URLSession = URLSession.shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.urlSession = sharedSession
        self.decoder = decoder
    }
}

extension DefaultWebSocketConnectionFactory: WebSocketConnectionFactory {
    public func open<Incoming: Decodable & Sendable>(url: URL) -> WebSocketConnection<Incoming> {
        var request = URLRequest(url: url)
        
        loadPersistentCookies()
        
        if let url = request.url {
            if let cookieHeader = getCookieStorage()[url.host ?? ""] {
                request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
            } else {
                print("No manually stored cookies for \(url.host ?? "unknown host").")
            }
        }
        
        let webSocketTask = urlSession.webSocketTask(with: request)

        return WebSocketConnection(
            webSocketTask: webSocketTask,
            decoder: decoder
        )
    }
}
