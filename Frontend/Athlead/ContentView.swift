//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    
    @State private var isLoggedIn = false // Status for authentication
    @State private var role: String = "User" // User role
    @State private var isLoading = true // Loading status

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Athlead wird geladen...")
            } else {
                TabView {
                    if isLoggedIn {
                        MainPageView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Hauptseite")
                            }
                        
                        if role.uppercased() == "ADMIN" {
                            AdminOverviewView()
                                .tabItem {
                                    Image(systemName: "person.3.fill")
                                    Text("Administration")
                                }
                        } else if role.uppercased() == "JUDGE" {
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
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                            .tabItem {
                                Image(systemName: "person.fill")
                                Text("Login")
                            }
                    }
                }
            }
        }
        .onAppear {
            Task {
                isLoading = true
                
                if let isLogged = await isUserLoggedIn() {
                    isLoggedIn = isLogged.is_logged_in
                    role = isLogged.role
                } else {
                    isLoggedIn = false
                    role = "User"
                }
                
                print("User is logged in: \(isLoggedIn)")
                print("User role: \(role)")
                isLoading = false
            }
        }
    }
}
#Preview {
    ContentView()
}
