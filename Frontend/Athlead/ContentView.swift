//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    enum Role {
        case User
        case Judge
        case Admin
    }
    @State private var isLoggedIn = true // Status für Authentifizierung
    @State private var role : Role = .Admin // Status für Authentifizierung


    var body: some View {
        TabView {
            if(isLoggedIn) {
                MainPageView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Hauptseite")
                    }
                if (role == .Admin) {
                   AdminOverviewView()
                        .tabItem {
                            Image(systemName: "person.3.fill")
                            Text("Administration")
                        }
                } else if(role == .Judge) {
                    JudgeOverviewView()
                        .tabItem {
                            Image(systemName: "sportscourt")
                            Text("Wettkämpfe")
                        }
                }
                YourProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profil")
                    }
                        
                        

            } else // Is not logged in
            {
                LoginRegisterView(isLoggedIn: $isLoggedIn)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Login")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
