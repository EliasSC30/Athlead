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
                    NavigationLink(destination: ManageSportfests()) {
                        Label("Manage Sportfests", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: LocationManagerView()) {
                        Label("Manage Locations", systemImage: "mappin.and.ellipse")
                    }
                }
                
                // Competitions Management Section
                Section(header: Text("Contests")) {
                    NavigationLink(destination: AddContestView()) {
                        Label("Add contest templates", systemImage: "plus.square")
                    }
                    NavigationLink(destination: ManageContestView()) {
                        Label("Manage contest templates", systemImage: "gearshape")
                    }
                }
                
                // Reports and Analytics Section
                Section(header: Text("Reports & Analytics")) {
                    NavigationLink(destination: AdminSportfestStatsView()) {
                        Label("View Sportfest reports", systemImage: "chart.bar")
                    }
                    NavigationLink(destination: AdminParticipationStatsView()) {
                        Label("Participation Stats", systemImage: "percent")
                    }
                    NavigationLink(destination: AdminCertificateGenerationView()) {
                        Label("Certificate Generation", systemImage: "doc.badge.plus")
                    }
                }
                
                // Administrative Settings
                Section(header: Text("Admin Settings")) {
                    NavigationLink(destination: CSVManagementView()){
                        Label("CSV Management", systemImage: "doc.text")
                    }
                    NavigationLink(destination: PersonManagementView()) {
                        Label("User Management", systemImage: "person.3")
                    }
                    NavigationLink(destination: AdminAuditLogView()) {
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
