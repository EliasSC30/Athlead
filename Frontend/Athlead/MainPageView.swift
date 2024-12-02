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
    
    
    private let apiURL = "http://localhost:8000";
    
    
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
                            
                            if upcoming_sportsfests.isEmpty {
                                Text("Keine Wettkämpfe in nächster Zeit")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                            
                            ForEach(upcoming_sportsfests, id: \.self) { sportfest in
                                NavigationLink(destination: EventDetailView(id: sportfest.ID, name: sportfest.NAME, start: sportfest.START, end: sportfest.END, locationID: sportfest.LOCATION_ID, contactPersonID: sportfest.CONTACTPERSON_ID, detailsID: sportfest.DETAILS_ID)) {
                                    EventCard(eventName: sportfest.NAME, date: sportfest.START)
                                }
                            }
                        
                        }
                    }
                    // Past Weetkämpfe
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
                                NavigationLink(destination: EventDetailView(id: sportfest.ID, name: sportfest.NAME, start: sportfest.START, end: sportfest.END, locationID: sportfest.LOCATION_ID, contactPersonID: sportfest.CONTACTPERSON_ID, detailsID: sportfest.DETAILS_ID)) {
                                    EventCard(eventName: sportfest.NAME, date: sportfest.END)
                                }
                            }
                        
                        }
                    }

                    // Beste Sportart
                   /* Section(header: Text("Deine beste Sportart")
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
                    } */
                }
                .padding(.vertical)
            }
            .navigationTitle("Athlead")
            .onAppear(perform: loadSportFests)
        }
    }
    
    
    private func loadSportFests() {
        let url = URL(string: apiURL + "/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error)")
                return
            }
            
            guard let data = data, let sportFestsResponse = try? JSONDecoder().decode(SportFestResponse.self, from: data) else {
                print("Failed to decode sportfests")
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
                        return
                    }
                    
                    guard let detailData = detailData, let detailsResponse = try? JSONDecoder().decode(DetailsResponse.self, from: detailData) else {
                        print("Failed to decode details")
                        return
                    }
                    
                    if self.past_sportfests.contains(where: { $0.ID == sportFestID }) || self.upcoming_sportsfests.contains(where: { $0.ID == sportFestID }) {
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
                                
                    
                    
                    
                }.resume()
            }
            
        }.resume()
        
    
    }
    
    struct SportFestDisplay: Identifiable, Hashable {
        let ID: String
        let DETAILS_ID: String
        let CONTACTPERSON_ID: String
        let NAME: String
        let LOCATION_ID: String
        let START: Date
        let END: Date
        
        var id: String { return self.ID }
    }
    
    struct SportFestResponse: Decodable {
        let data: [SportFest]
        let results: Int
        let status: String
    }
    
    struct SportFest: Identifiable, Decodable {
        let id: String
        let details_id: String
    }
    
    struct DetailsResponse: Decodable {
        let data: Detail
        let status: String
    }
    struct Detail: Identifiable, Decodable {
        let ID: String
        let CONTACTPERSON_ID: String
        let NAME: String
        let LOCATION_ID: String
        let START: String
        let END: String
        
        var id: String { return self.ID }
    }
}

enum MedalType {
    case gold, silver, bronze
}

// Components
struct EventCard: View {
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
