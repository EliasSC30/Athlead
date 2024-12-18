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
            ContentView()
        }
    }
    
    
    private func loadCookiesFromStorage() {
        let defaults = UserDefaults.standard
        guard let savedCookies = defaults.array(forKey: "cookies") as? [[String: Any]] else { return }
        for cookieData in savedCookies {
            if let cookie = HTTPCookie(properties: Dictionary(uniqueKeysWithValues: cookieData.map { (HTTPCookiePropertyKey($0.key), $0.value) })) {
                HTTPCookieStorage.shared.setCookie(cookie)
                print(HTTPCookieStorage.shared.cookies)
                print(cookie)
            }
        }
    }
}
