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

struct Placing : Identifiable {
    let id = UUID()
    let name: String
    let place : Int8
}


struct CompetitionsOverviewView: View {
    enum CompType {
        case LongJump
        case HundredMeterRun
        case HighJump
    }
    
    let competitions = [
        Competition(name: "Weitsprung", date: "20.11.2024", location: "Stadion A"),
        Competition(name: "100m Lauf", date: "21.11.2024", location: "Stadion B"),
        Competition(name: "Hochsprung", date: "22.11.2024", location: "Stadion C")
    ]
    
    let longJumpPlacings = [
        Placing(name: "Elias jump", place: 1),
        Placing(name: "Jan jump", place: 2)
    ]
    
    let hundredMeterRunPlacings = [
        Placing(name: "Elias Ran", place: 1),
        Placing(name: "Jan RAn", place: 2)
    ]
    
    let highJumpPlacings = [
        Placing(name: "Elias high jump", place: 1),
        Placing(name: "Jan high jump", place: 2)
    ]
    
    func getPlacings(for comp: String) -> [Placing]
    {
        switch(comp)
        {
        case "Weitsprung":
            return longJumpPlacings;
        case "100m Lauf":
            return hundredMeterRunPlacings;
        case "Hochsprung":
            return highJumpPlacings;
        default:
            return [];
        }
        
    }

    var body: some View {
        NavigationView {
            List(competitions) { competition in
                NavigationLink(destination: CompetitionDetailView(competition: competition, placings: getPlacings(for: competition.name))) {
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
    let placings: [Placing]

    var body: some View {
        VStack(spacing: 20) {
            Text(competition.name)
                .font(.largeTitle)
                .bold()
            Text("Datum: \(competition.date)")
            Text("Ort: \(competition.location)")
            List(placings, id: \.name) {
                placing in Text(placing.name + " " + placing.place.formatted())
            }
            .padding(.top, 5)
            .foregroundColor(.primary)
        }
        .padding()
        .navigationTitle("Details")
    }
}
