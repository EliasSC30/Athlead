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
    @State private var selectedParallelClassGroup: String = "All"
    @State private var selectedDisplayMetric: String = "Points" // Default metric
    @State private var isSettingsSheetPresented: Bool = false // State for showing settings sheet


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
                ScrollView {
                    VStack {
                        if let contests = sportFestResults?.contests {
                            if !contests.isEmpty {
                                ForEach(contests, id: \.id) { contest in
                                    ContestChartView(
                                        contest: contest,
                                        selectedGender: selectedGender,
                                        selectedGrade: selectedGrade,
                                        selectedParallelClassGroup: selectedParallelClassGroup,
                                        selectedDisplayMetric: selectedDisplayMetric
                                    )
                                }
                            } else {
                                Text("No contests available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
        .navigationTitle("Stats for \(sportfest.details_name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isSettingsSheetPresented.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                }.disabled(isLoading || sportFestResults == nil || sportFestResults?.contests.isEmpty ?? true)
            }
        }
        .sheet(isPresented: $isSettingsSheetPresented) {
            SettingsSheet(
                selectedGender: $selectedGender,
                selectedGrade: $selectedGrade,
                selectedParallelClassGroup: $selectedParallelClassGroup,
                selectedDisplayMetric: $selectedDisplayMetric,
                isPresented: $isSettingsSheetPresented,
                uniqueGrades: uniqueGrades(),
                uniqueParallelClassGroups: uniqueParallelClassGroups()
            )
        }
    }
    
    // MARK: - Filters Section
    @ViewBuilder
    private func filtersSection() -> some View {
        HStack {
            Picker("Gender", selection: $selectedGender) {
                Text("All").tag("All")
                Text("Male").tag("Male")
                Text("Female").tag("Female")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Picker("Grade", selection: $selectedGrade) {
                Text("All").tag("All")
                ForEach(uniqueGrades(), id: \.self) { grade in
                    Text(grade).tag(grade)
                }
            }
            
            Picker("Group", selection: $selectedParallelClassGroup) {
                Text("All").tag("All")
                ForEach(uniqueParallelClassGroups(), id: \.self) { group in
                    Text("Grade \(group)").tag(group)
                }
            }
        }
        .padding()
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

    // MARK: - Helpers
    func uniqueGrades() -> [String] {
        guard let sportFestResults = sportFestResults else { return [] }
        let allGrades = sportFestResults.contests.flatMap { $0.results.compactMap { $0.p_grade } }
        return Array(Set(allGrades)).sorted()
    }

    func uniqueParallelClassGroups() -> [String] {
        guard let sportFestResults = sportFestResults else { return [] }
        let allGroups = sportFestResults.contests.flatMap { $0.results.compactMap { grade in
            grade.p_grade?.prefix(while: { $0.isNumber })
        }}
        return Array(Set(allGroups)).sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }).map { String($0) }
    }
}

struct ContestChartView: View {
    let contest: ContestWithResults
    let selectedGender: String
    let selectedGrade: String
    let selectedParallelClassGroup: String
    let selectedDisplayMetric: String

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Contest: \(contest.contest_name)")
                    .font(.headline)
                if selectedDisplayMetric.lowercased() == "value" {
                    Text("Unit: \(contest.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }.padding()
                
                
            
            Chart(filteredResults()) { result in
                if selectedDisplayMetric == "Points" {
                    BarMark(
                        x: .value("Name", result.p_f_name + " " + result.p_l_name),
                        y: .value("Points", result.points)
                    )
                } else {
                    BarMark(
                        x: .value("Name", result.p_f_name + " " + result.p_l_name),
                        y: .value("Value", result.value)
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    func filteredResults() -> [PersonWithResult] {
        return contest.results.filter { result in
            (selectedGender.lowercased() == "all" || result.p_gender.lowercased() == selectedGender.lowercased()) &&
            (selectedGrade.lowercased() == "all" || result.p_grade?.lowercased() == selectedGrade.lowercased()) &&
            (selectedParallelClassGroup == "All" ||
             (result.p_grade!.prefix(while: { $0.isNumber }) == selectedParallelClassGroup))
        }
    }
}
struct SettingsSheet: View {
    @Binding var selectedGender: String
    @Binding var selectedGrade: String
    @Binding var selectedParallelClassGroup: String
    @Binding var selectedDisplayMetric: String
    @Binding var isPresented: Bool
    
    
    let uniqueGrades: [String]
    let uniqueParallelClassGroups: [String]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filters")) {
                    Picker("Gender", selection: $selectedGender) {
                        Text("All").tag("All")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Picker("Grade", selection: $selectedGrade) {
                        Text("All").tag("All")
                        ForEach(uniqueGrades, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }

                    Picker("Group", selection: $selectedParallelClassGroup) {
                        Text("All").tag("All")
                        ForEach(uniqueParallelClassGroups, id: \.self) { group in
                            Text("Grade \(group)").tag(group)
                        }
                    }
                }

                Section(header: Text("Display Metric")) {
                    Picker("Metric", selection: $selectedDisplayMetric) {
                        Text("Points").tag("Points")
                        Text("Value").tag("Value")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}
