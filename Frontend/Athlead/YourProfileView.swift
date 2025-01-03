//
//  YourProfileView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//
import SwiftUI

struct YourProfileView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section(header: Text("Your Profile")) {
                    HStack {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .padding(.trailing, 10)
                        VStack(alignment: .leading) {
                            Text("Nathanäl Hendrik Özcan-Wichmann")
                                .font(.headline)
                            Text("Igelgruppe")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button (action: {
                        isLoggedIn = false;
                        UserRole = "Contestant";
                        UserId = "";
                        SessionToken = "";
                        clearCookies();
                    }){
                        Label("Log Out", systemImage: "arrowshape.turn.up.backward")
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
                
                // Achievements Section
                Section(header: Text("Achievements")) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text("Gold Medal in Sprint")
                                .font(.body)
                            Text("Achieved: 12.4 seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("Long Jump")
                                .font(.body)
                            Text("Target: 5.5m, Achieved: 5.3m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Settings Section
                Section(header: Text("Settings")) {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    NavigationLink(destination: Text("Notification Preferences")) {
                        Label("Notifications", systemImage: "bell")
                    }
                    NavigationLink(destination: Text("Privacy Settings")) {
                        Label("Privacy", systemImage: "lock")
                    }
                }
                
                // More Info Section
                Section(header: Text("More")) {
                    NavigationLink(destination: Text("Event Schedule")) {
                        Label("Event Schedule", systemImage: "calendar")
                    }
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    NavigationLink(destination: Text("About the App")) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Sportfest Overview")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct LogoutView: View {

    var body: some View {
        Text("You have been logged out.")
            .font(.title)
            .onAppear(perform: logout)
    }
    
    func logout(){
        // Remove cookies stored in memory
        clearCookies()
        
        // Delete the persistent cookies file
        do {
            if FileManager.default.fileExists(atPath: getCookieFilePath().path()) {
                try FileManager.default.removeItem(at: getCookieFilePath())
                print("Cookies file deleted.")
            } else {
                print("No cookies file found to delete.")
            }
        } catch {
            print("Failed to delete cookies file: \(error)")
        }
        
        // Clear HTTPCookieStorage (if applicable)
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
    }
}
