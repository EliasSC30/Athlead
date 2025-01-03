//
//  AdminSportfestStatsView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.01.25.
//

import SwiftUI

struct AdminSportfestStatsView: View {
    
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
                                    destination: StatsViewForSportFestView(sportfest: sportfest)
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
                                    destination: StatsViewForSportFestView(sportfest: sportfest)
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
                                    destination: StatsViewForSportFestView(sportfest: sportfest)
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

struct StatsViewForSportFestView: View {

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var sportFestResults: SportfestResultMasterResponse? = nil
    @State private var selectedGender: String = "All"
    @State private var selectedGrade: String = "All"

    let sportfest: SportfestData

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfest stats...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    HStack {
                        Picker("Gender", selection: $selectedGender) {
                            Text("All").tag("All")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .blur(radius: sportFestResults?.contests.isEmpty ?? true ? 2 : 0)
                        
                        
                        Picker("Grade", selection: $selectedGrade) {
                            Text("All").tag("All")
                            ForEach(uniqueGrades(), id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }.blur(radius: sportFestResults?.contests.isEmpty ?? true ? 2 : 0)
                    }
                    .padding()

                    ZStack {
                        Chart(filteredResults()) {
                            BarMark(
                                x: .value("Name", $0.p_f_name + " " + $0.p_l_name),
                                y: .value("Points", $0.points)
                            )
                        }
                        .padding()
                        .blur(radius: sportFestResults?.contests.isEmpty ?? true ? 5 : 0)
                        .overlay(
                            sportFestResults?.contests.isEmpty ?? true ?
                            Text("No data for this sportfest available")
                                .foregroundColor(.black)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                                .padding()
                            : nil
                        )
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .navigationTitle("Stats for \(sportfest.details_name)")
    }

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

    func filteredResults() -> [PersonWithResult] {
        guard let sportFestResults = sportFestResults else { return [] }
        let allResults = sportFestResults.contests.flatMap { $0.results }

        return allResults.filter { result in
            (selectedGender == "All" || result.p_gender == selectedGender) &&
            (selectedGrade == "All" || result.p_grade == selectedGrade)
        }
    }

    func uniqueGrades() -> [String] {
        guard let sportFestResults = sportFestResults else { return [] }
        let allGrades = sportFestResults.contests.flatMap { $0.results.compactMap { $0.p_grade } }
        return Array(Set(allGrades)).sorted()
    }
}
