//
//  AdminOverviewView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//


import SwiftUI

struct AdminOverviewView: View {
    var body: some View {
        NavigationView {
            List {
                // Sportfests Management Section
                Section(header: Text("Sportfests")) {
                    NavigationLink(destination: CreateSportfestView()) {
                        Label("Create New Sportfest", systemImage: "plus.circle")
                    }
                    NavigationLink(destination: Text("View All Sportfests")) {
                        Label("Manage Sportfests", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: LocationManagerView()) {
                        Label("Manage Locations", systemImage: "mappin.and.ellipse")
                    }
                }
                
                // Competitions Management Section
                Section(header: Text("Contests")) {
                    NavigationLink(destination: Text("Add New Competition")) {
                        Label("Add Contests", systemImage: "plus.square")
                    }
                    NavigationLink(destination: Text("Manage Competitions")) {
                        Label("Manage Contests", systemImage: "gearshape")
                    }
                    NavigationLink(destination: Text("Assign Competitions to Sportfests")) {
                        Label("Assign to Sportfest", systemImage: "arrowshape.turn.up.right")
                    }
                }
                
                // Reports and Analytics Section
                Section(header: Text("Reports & Analytics")) {
                    NavigationLink(destination: Text("View Performance Reports")) {
                        Label("Performance Reports", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: Text("Generate Participation Statistics")) {
                        Label("Participation Stats", systemImage: "percent")
                    }
                }
                
                // Administrative Settings
                Section(header: Text("Admin Settings")) {
                    NavigationLink(destination: Text("User Management")) {
                        Label("User Management", systemImage: "person.3")
                    }
                    NavigationLink(destination: Text("System Settings")) {
                        Label("System Settings", systemImage: "gear")
                    }
                    NavigationLink(destination: Text("Audit Logs")) {
                        Label("Audit Logs", systemImage: "doc.plaintext")
                    }
                }
            }
            .navigationTitle("Admin Overview")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct AdminOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        AdminOverviewView()
    }
}
