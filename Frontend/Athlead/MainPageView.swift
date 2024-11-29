//
//  MainPageView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI

struct MainPageView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Nächste Wettkämpfe
                    Section(header: Text("Nächste Wettkämpfe")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)) {
                        VStack(spacing: 15) {
                            NavigationLink(destination: EventDetailView(eventName: "Bundesjugendspiele - Leichtathletik", date: "22. November 2024")) {
                                EventCard(eventName: "Bundesjugendspiele - Leichtathletik", date: "22. November 2024")
                            }
                            NavigationLink(destination: EventDetailView(eventName: "Schulsportfest", date: "15. Dezember 2024")) {
                                EventCard(eventName: "Schulsportfest", date: "15. Dezember 2024")
                            }
                        }
                    }

                    // Beste Sportart
                    Section(header: Text("Deine beste Sportart")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)) {
                        NavigationLink(destination: BestSportDetailView(sportName: "Weitwurf", score: "85 Meter")) {
                            BestSportCard(sportName: "Weitwurf", score: "85 Meter")
                        }
                    }

                    // Auszeichnungen
                    Section(header: Text("Auszeichnungen")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)) {
                        NavigationLink(destination: AwardDetailView(awardName: "Goldmedaille - Sprint", year: 2024, medalType: .gold)) {
                            AwardCard(awardName: "Goldmedaille - Sprint", year: 2024, medalType: .gold)
                        }
                        NavigationLink(destination: AwardDetailView(awardName: "Silbermedaille - Weitsprung", year: 2023, medalType: .silver)) {
                            AwardCard(awardName: "Silbermedaille - Weitsprung", year: 2023, medalType: .silver)
                        }
                        NavigationLink(destination: AwardDetailView(awardName: "Bronzemedaille - Hochsprung", year: 2022, medalType: .bronze)) {
                            AwardCard(awardName: "Bronzemedaille - Hochsprung", year: 2022, medalType: .bronze)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Athlead")
        }
    }
}
enum MedalType {
    case gold, silver, bronze
}

// Components
struct EventCard: View {
    let eventName: String
    let date: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(eventName)
                    .font(.headline)
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "calendar")
                .foregroundColor(.blue)
                .font(.title)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct BestSportCard: View {
    let sportName: String
    let score: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(sportName)
                    .font(.headline)
                Text("Bestleistung: \(score)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
    }
}

struct AwardCard: View {
    let awardName: String
    let year: Int
    let medalType: MedalType

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(awardName)
                    .font(.headline)
                Text("Jahr: " + String(year))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: medalType == .gold ? "medal" :
                                medalType == .silver ? "medal" :
                                "medal")
                .foregroundColor(medalType == .gold ? .yellow :
                                medalType == .silver ? .gray :
                                .brown)
                .font(.title)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
    }
}
