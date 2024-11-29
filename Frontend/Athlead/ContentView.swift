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
    @State private var role : Role = .Judge // Status für Authentifizierung


    var body: some View {
        TabView {
            MainPageView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Hauptseite")
                }
            if(isLoggedIn) {

                if (role == .Admin) {
                    CompetitionsOverviewView()
                        .tabItem {
                            Image(systemName: "sportscourt")
                            Text("Wettkämpfe")
                        }
                } else if(role == .Judge) {
                    JudgeView()
                        .tabItem {
                            Image(systemName: "sportscourt")
                            Text("Wettkämpfe")
                        }
                } else if(role == .User) {
                    CompetitionsOverviewView()
                       .tabItem {
                           Image(systemName: "sportscourt")
                           Text("Wettkämpfe")
                       }
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
