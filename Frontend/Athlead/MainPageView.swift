//
//  MainPageView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//
import SwiftUI
import Foundation

struct MainPageView: View {
    
    @State private var upcoming_sportsfests: [SportFestDisplay] = []
    @State private var past_sportfests: [SportFestDisplay] = []
    
    
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?    
    
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfests...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Section(header: Text("Nächste Wettkämpfe")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)) {
                                    VStack(spacing: 15) {
                                        
                                        if upcoming_sportsfests.isEmpty {
                                            Text("Keine Wettkämpfe in nächster Zeit")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                        }
                                        
                                        ForEach(upcoming_sportsfests, id: \.self) { sportfest in
                                            EventCard(eventName: sportfest.NAME, sportfestID: sportfest.ID)
                                        }
                                        
                                    }
                                }
                            Section(header: Text("Vergangene Wettkämpfe")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)) {
                                    VStack(spacing: 15) {
                                        
                                        if past_sportfests.isEmpty {
                                            Text("Keine bisherigen Wettkämpfe")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                        }
                                        
                                        ForEach(past_sportfests, id: \.self) { sportfest in
                                            EventCard(eventName: sportfest.NAME, sportfestID: sportfest.ID)
                                        }
                                        
                                    }
                                }
                        }
                        .padding(.vertical)
                    }
                    .navigationTitle("Athlead")
                }
            }
        }.onAppear(perform: loadSportFests)
    }
    
    
    private func loadSportFests() {
        isLoading = true
        errorMessage = nil
        
        let url = URL(string: apiURL + "/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch sportfests"
                }
                return
            }
            
            guard let data = data, let sportFestsResponse = try? JSONDecoder().decode(SportFestsResponse.self, from: data) else {
                print("Failed to decode sportfests")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch sportfests"
                }
                return
            }
            
            for sportFest in sportFestsResponse.data {
                let sportFestID = sportFest.id
                let detailUrl = URL(string: apiURL + "/details/\(sportFest.details_id)")!
                var detailRequest = URLRequest(url: detailUrl)
                detailRequest.httpMethod = "GET"
                detailRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: detailRequest) { detailData, detailResponse, detailError in
                    if let detailError = detailError {
                        print("Error fetching locations: \(detailError)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Failed to fetch sportfests"
                        }
                        return
                    }
                    
                    guard let detailData = detailData, let detailsResponse = try? JSONDecoder().decode(DetailResponse.self, from: detailData) else {
                        print("Failed to decode details")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Failed to fetch sportfests"
                        }
                        return
                    }
                    
                    if self.past_sportfests.contains(where: { $0.ID == sportFestID }) || self.upcoming_sportsfests.contains(where: { $0.ID == sportFestID }) {
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                        return
                    }
                    
                    
                    let formatter = DateFormatter()
                    
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    
                    let formattedStartDate = formatter.date(from: detailsResponse.data.START) ?? Date();
                    let formattedEndDate = formatter.date(from: detailsResponse.data.END) ?? Date();
                    
                    
                    let sportFest = SportFestDisplay(ID: sportFestID, DETAILS_ID: detailsResponse.data.ID, CONTACTPERSON_ID: detailsResponse.data.CONTACTPERSON_ID, NAME: detailsResponse.data.NAME, LOCATION_ID: detailsResponse.data.LOCATION_ID, START: formattedStartDate, END: formattedEndDate)
                    
                    if formattedEndDate < Date() {
                        self.past_sportfests.append(sportFest)
                    } else {
                        self.upcoming_sportsfests.append(sportFest)
                    }
                    
                    self.upcoming_sportsfests.sort(by: { $0.START < $1.START })
                    self.past_sportfests.sort(by: { $0.START < $1.START })
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = nil
                    }
                                
                    
                    
                    
                }.resume()
            }
            
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = nil
            }
        }.resume()
        
    
    }
}

enum MedalType {
    case gold, silver, bronze
}

// Components
struct EventCardOld: View {
    let eventName: String
    let date: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(eventName)
                    .font(.headline)
                Text(date.formatted(date: .complete, time: .omitted))
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
    let year: Int32
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
            Image(systemName: "medal")
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
