//
//  Competition.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI

struct Competition: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let location: String
}

struct CompetitionsOverviewView: View {
    let competitions = [
        Competition(name: "Weitsprung", date: "20.11.2024", location: "Stadion A"),
        Competition(name: "100m Lauf", date: "21.11.2024", location: "Stadion B"),
        Competition(name: "Hochsprung", date: "22.11.2024", location: "Stadion C")
    ]

    var body: some View {
        NavigationView {
            List(competitions) { competition in
                NavigationLink(destination: CompetitionDetailView(competition: competition)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(competition.name)
                                .font(.headline)
                            Text("\(competition.date) - \(competition.location)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Wettkämpfe")
        }
    }
}

struct CompetitionDetailView: View {
    let competition: Competition

    var body: some View {
        VStack(spacing: 20) {
            Text(competition.name)
                .font(.largeTitle)
                .bold()
            Text("Datum: \(competition.date)")
            Text("Ort: \(competition.location)")
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}
