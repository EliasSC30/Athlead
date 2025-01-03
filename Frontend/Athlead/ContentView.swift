//
//  ContentView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct ContentView: View {
    @State private var isLoading = true // Loading status
    @State private var successfullLogin = User != nil;

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Athlead wird geladen...")
            } else {
                TabView {
                    if successfullLogin {
                        MainPageView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Hauptseite")
                            }
                        
                        if User.unsafelyUnwrapped.ROLE.uppercased() == "ADMIN" {
                            AdminOverviewView()
                                .tabItem {
                                    Image(systemName: "person.3.fill")
                                    Text("Administration")
                                }
                        } else if User.unsafelyUnwrapped.ROLE.uppercased() == "JUDGE" {
                            JudgeOverviewView()
                                .tabItem {
                                    Image(systemName: "sportscourt")
                                    Text("Wettkämpfe")
                                }
                        } else if User.unsafelyUnwrapped.ROLE.uppercased() == "CONTESTANT" {
                            ParticipantView()
                                .tabItem {
                                    Image(systemName: "sportscourt")
                                    Text("Meine Wettkämpfe")
                                }
                        }
                        
                        YourProfileView()
                            .tabItem {
                                Image(systemName: "person.fill")
                                Text("Profil")
                            }
                    } else {
                        LoginView(loginAttemptHappened:{() -> Void in successfullLogin = User != nil; })
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
                
                fetch("\(apiURL)/loggedin", IsLoggedIn.self) { response in
                    switch response {
                    case .success(let loggedIn):
                        User = loggedIn.user;
                    case .failure(let err): print(err);
                    }
                }
            
                isLoading = false
            }
        }
    }
}
