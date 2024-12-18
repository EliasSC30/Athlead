//
//  AthleadApp.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI

@main
struct AthleadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().onAppear(perform: loadCookiesFromStorage)
        }
    }
    
    
    private func loadCookiesFromStorage() {
        
        var configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        
    }
}
