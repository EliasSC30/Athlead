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
        loadPersistentCookies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
