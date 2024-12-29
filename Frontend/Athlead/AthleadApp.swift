//
//  AthleadApp.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI

@main
struct AthleadApp: App {
    
    init(){
        #if targetEnvironment(simulator)
        #else
            loadPersistentCookies()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
