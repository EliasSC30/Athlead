//
//  AthleadApp.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI

struct WebSocketConnectionFactoryEnvironmentKey: EnvironmentKey {
    static var defaultValue: WebSocketConnectionFactory = DefaultWebSocketConnectionFactory()
}

extension EnvironmentValues {
    var webSocketConnectionFactory: WebSocketConnectionFactory {
        get { self[WebSocketConnectionFactoryEnvironmentKey.self] }
        set { self[WebSocketConnectionFactoryEnvironmentKey.self] = newValue }
    }
}

@main
struct AthleadApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView().onAppear(perform: loadPersistentCookies)
        }
    }
    
}
