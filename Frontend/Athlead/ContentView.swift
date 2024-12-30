//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    
    @State private var isLoggedIn = false // Status for authentication
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
                        
                        if UserRole!.uppercased() == "ADMIN" {
                            AdminOverviewView()
                                .tabItem {
                                    Image(systemName: "person.3.fill")
                                    Text("Administration")
                                }
                        } else if UserRole!.uppercased() == "JUDGE" {
                            JudgeOverviewView()
                                .tabItem {
                                    Image(systemName: "sportscourt")
                                    Text("Wettkämpfe")
                                }
                        } else if UserRole!.uppercased() == "CONTESTANT" {
                            ParticipantView()
                                .tabItem {
                                    Image(systemName: "sportscourt")
                                    Text("Meine Wettkämpfe")
                                }
                        }
                        
                        YourProfileView(isLoggedIn: $isLoggedIn)
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

                /* <<< Uncomment to go back
                let isLogged = await isUserLoggedIn();
                
                if isLogged.is_logged_in {
                    isLoggedIn = isLogged.is_logged_in
                    role = isLogged.role.uppercased()
                } else {
                    isLoggedIn = false
                    role = "User"
                }
                  <<< Uncomment to go back */
                
                // <<< Remove to go back
                
                fetch(from: "\(apiURL)/loggedin", ofType: IsLoggedIn.self) { response in
                    switch response {
                    case .success(let loggedIn):
                        isLoggedIn = loggedIn.is_logged_in;
                        UserRole = loggedIn.role.uppercased();
                    case .failure(let err): print(err);
                    }
                }
                // <<< Remove to go back
            
                isLoading = false
            }
        }
    }
}
#Preview {
    ContentView()
}
