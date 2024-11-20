//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = true // Status für Authentifizierung

    var body: some View {
        TabView {
            MainPageView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Main Page")
                }
            
            if isLoggedIn {
                CompetitionsOverviewView()
                    .tabItem {
                        Image(systemName: "sportscourt")
                        Text("Wettkämpfe")
                    }
            } else {
                LockedTabView()
                    .tabItem {
                        Image(systemName: "sportscourt")
                        Text("Wettkämpfe")
                    }
            }
            LoginRegisterView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Login")
                }
        }
    }
}

#Preview {
    ContentView()
}
