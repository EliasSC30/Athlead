//
//  AdminCertificateGenerationView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 10.01.25.
//

import SwiftUI


struct AdminCertificateGenerationView: View {
    
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
                                    destination: SportfestCerifacteGeneratorView(sportfest: sportfest)
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
                                    destination: SportfestCerifacteGeneratorView(sportfest: sportfest)
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
                                    destination: SportfestCerifacteGeneratorView(sportfest: sportfest)
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

struct SportfestCerifacteGeneratorView: View {
    
    let sportfest: SportfestData
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @State private var contestantPoints: [PersonWithPoint] = []
    
    @State private var ehrenurkundePercentage: Double = 15.0
    @State private var siegerurkundePercentage: Double = 30.0
    @State private var teilnehmerurkundePercentage: Double = 55.0
    
    // Track contestants for each certificate
    @State private var ehrenurkundeContestants: [PersonWithPoint] = []
    @State private var siegerurkundeContestants: [PersonWithPoint] = []
    @State private var teilnehmerurkundeContestants: [PersonWithPoint] = []
    
    // Show the sheet after generation
    @State private var isGeneratedSheet: Bool = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfest results...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: 20) {
                    Text("Generate Certificates for \(sportfest.details_name)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()

                    // Sliders for selecting certificate percentages
                    VStack(spacing: 10) {
                        Text("Ehrenurkunde: \(Int(ehrenurkundePercentage))%")
                            .font(.headline)
                        Slider(value: $ehrenurkundePercentage, in: 0...max(1, 100 - siegerurkundePercentage - teilnehmerurkundePercentage), step: 1)
                            .accentColor(.blue)

                        Text("Siegerurkunde: \(Int(siegerurkundePercentage))%")
                            .font(.headline)
                        Slider(value: $siegerurkundePercentage, in: 0...max(1, 100 - ehrenurkundePercentage - teilnehmerurkundePercentage), step: 1)
                            .accentColor(.green)

                        Text("Teilnehmerurkunde: \(Int(teilnehmerurkundePercentage))%")
                            .font(.headline)
                        Slider(value: $teilnehmerurkundePercentage, in: 0...max(1, 100 - ehrenurkundePercentage - siegerurkundePercentage), step: 1)
                            .accentColor(.orange)
                    }
                    .padding()

                    // Generate Button
                    Button(action: {
                        // Action when pressed
                        generateCertificates()
                    }) {
                        Text("Generate Certificates")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()

                }
                .padding()
            }
        }
        .onAppear(perform: loadResults)
        .refreshable {
            loadResults()
        }
        .sheet(isPresented: $isGeneratedSheet) {
            VStack(spacing: 20) {
                Text("Certificates Generated")
                    .font(.title)
                    .padding()
                
                // Display how many contestants received each certificate
                Text("Ehrenurkunde: \(ehrenurkundeContestants.count) contestants")
                    .font(.headline)
                Text("Siegerurkunde: \(siegerurkundeContestants.count) contestants")
                    .font(.headline)
                Text("Teilnehmerurkunde: \(teilnehmerurkundeContestants.count) contestants")
                    .font(.headline)
                
                // Send via Mail Button (simulated)
                Button(action: {
                    sendCertificatesByEmail()
                }) {
                    Text("Send Certificates via Mail")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding()
            }
            .padding()
            .onAppear(perform: generateCertificates)
        }
    }
    
    // Function to generate certificates
    func generateCertificates() {
        // Clear previous contestants
        ehrenurkundeContestants.removeAll()
        siegerurkundeContestants.removeAll()
        teilnehmerurkundeContestants.removeAll()
        
        
        let totalContestants = contestantPoints.count
        
        
        // Calculate how many contestants should get each certificate based on the percentages
        let ehrenurkundeCount = Int(Double(totalContestants) * (ehrenurkundePercentage / 100)) + 1
        let siegerurkundeCount = Int(Double(totalContestants) * (siegerurkundePercentage / 100))
        
        ehrenurkundeContestants = Array(contestantPoints.prefix(ehrenurkundeCount))
        siegerurkundeContestants = Array(contestantPoints.dropFirst(ehrenurkundeCount).prefix(siegerurkundeCount))
        teilnehmerurkundeContestants = Array(contestantPoints.dropFirst(ehrenurkundeCount + siegerurkundeCount))
        
        isGeneratedSheet = true
    }
    
    // Function to simulate sending certificates by email
    func sendCertificatesByEmail() {
        print("Sending certificates via email...")
        // Add logic to send certificates via email here
    }
    
    func loadResults() {
        isLoading = true
        errorMessage = nil
        
        fetch("sportfests/\(sportfest.id)/results", SportFestResults.self) { result in
            switch result {
            case .success(let myData):
                errorMessage = nil
                contestantPoints = myData.contestants_totals
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

