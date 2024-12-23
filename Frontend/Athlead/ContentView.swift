//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    
    @State private var isLoggedIn = false // Status for authentication
    @State private var role: String = "Admin" // User role
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
            
                
                let isLogged = await isUserLoggedIn();
                
                if isLogged.is_logged_in {
                    isLoggedIn = isLogged.is_logged_in
                    role = isLogged.role.uppercased()
                } else {
                    isLoggedIn = false
                    role = "User"
                }
            
                isLoading = false
            }
        }
    }
}
#Preview {
    ContentView()
}
