//
//  AdminParticipationStatsView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.01.25.
//

import SwiftUI

struct AdminParticipationStatsView: View {
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @State var oldSportFests: [SportfestData] = []
    @State var currentSportFests: [SportfestData] = []
    @State var newSportfests: [SportfestData] = []
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfest stats...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                List {
                    Section(header: Text("Current Sportfests")) {
                        if currentSportFests.isEmpty {
                            Text("No current sportfests available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(currentSportFests, id: \.self) { sportfest in
                                NavigationLink(
                                    destination: AdminParticipationStatsDetailView(sportfest: sportfest)
                                ) {
                                    Label(
                                        sportfest.details_name,
                                        systemImage: "figure.disc.sports")
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Upcoming Sportfests")) {
                        if newSportfests.isEmpty {
                            Text("No upcoming sportfests available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(newSportfests, id: \.self) { sportfest in
                                NavigationLink(
                                    destination: AdminParticipationStatsDetailView(sportfest: sportfest)
                                ) {
                                    Label(
                                        sportfest.details_name,
                                        systemImage: "figure.run")
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Past Sportfests")) {
                        if oldSportFests.isEmpty {
                            Text("No past sportfests available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(oldSportFests, id: \.self) { sportfest in
                                NavigationLink(
                                    destination: AdminParticipationStatsDetailView(sportfest: sportfest)
                                ) {
                                    Label(
                                        sportfest.details_name,
                                        systemImage: "flag.pattern.checkered")
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Sportfests")
            }
        }.onAppear {
            loadData()
        }
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        fetch("sportfests", SportFestsResponse.self) { result in
            switch result {
            case .success(let myData):
                isLoading = false
                errorMessage = nil
                let sportFests = myData.data
                
                for sportfest in sportFests {
                    let startDate = stringToDate(sportfest.details_start)
                    let endDate = stringToDate(sportfest.details_end)
                    
                    
                    if endDate < Date() {
                        if currentSportFests.contains(sportfest) {
                            currentSportFests.removeAll(where: { $0 == sportfest })
                        }
                        if newSportfests.contains(sportfest) {
                            newSportfests.removeAll(where: { $0 == sportfest })
                        }
                        if !oldSportFests.contains(sportfest) {
                            oldSportFests.append(sportfest)
                        }
                    } else if endDate > Date() && startDate < Date() {
                        if oldSportFests.contains(sportfest) {
                            oldSportFests.removeAll(where: { $0 == sportfest })
                        }
                        if newSportfests.contains(sportfest) {
                            newSportfests.removeAll(where: { $0 == sportfest })
                        }
                        if !currentSportFests.contains(sportfest) {
                            currentSportFests.append(sportfest)
                        }
                    } else {
                        if currentSportFests.contains(sportfest) {
                            currentSportFests.removeAll(where: { $0 == sportfest })
                        }
                        if oldSportFests.contains(sportfest) {
                            oldSportFests.removeAll(where: { $0 == sportfest })
                        }
                        if !newSportfests.contains(sportfest) {
                            newSportfests.append(sportfest)
                        }
                    }
                }
                
                
            case .failure(let error):
                isLoading = false
                errorMessage = error.localizedDescription
                print("Error fetching data: \(error)")
            }
        }
    }
    func stringToDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: string) ?? Date()
    }
    
}


import Charts

struct AdminParticipationStatsDetailView: View {
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var sportFestResults: SportfestResultMasterResponse? = nil
    @State private var selectedGrouping: String = "Class" // Default grouping: "Class" or "Grade"

    let sportfest: SportfestData

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading participation stats...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    Picker("Group By", selection: $selectedGrouping) {
                        Text("Class").tag("Class")
                        Text("Grade").tag("Grade")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    let stats = participationStats()
                    if stats.isEmpty {
                        Text("No data available for this grouping.")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        Chart(stats, id: \.0) { group, count in
                            BarMark(
                                x: .value("Group", group),
                                y: .value("Participants", count)
                            )
                            .foregroundStyle(by: .value("Group", group))
                        }
                        .chartXAxisLabel("Group")
                        .chartYAxisLabel("Participants")
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .navigationTitle("Participation Stats")
    }

    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        let sportfest_id = sportfest.sportfest_id
        fetch("sportfests/\(sportfest_id)/results", SportfestResultMasterResponse.self) { result in
            switch result {
            case .success(let myData):
                sportFestResults = myData
                errorMessage = nil
                isLoading = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Participation Stats
    func participationStats() -> [(String, Int)] {
        guard let sportFestResults = sportFestResults else { return [] }

        let participants = sportFestResults.contests.flatMap { $0.results }
        let grouped: [String: Int]

        if selectedGrouping == "Class" {
            // Group by full class (e.g., "1a", "2b")
            grouped = Dictionary(grouping: participants, by: { $0.p_grade ?? "Unknown" })
                .mapValues { $0.count }
        } else {
            // Group by grade level (e.g., "1", "2")
            grouped = Dictionary(grouping: participants, by: { grade in
                String(grade.p_grade?.prefix(while: { $0.isNumber }) ?? "Unknown")
            })
            .mapValues { $0.count }
        }

        return grouped.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
    }
}
