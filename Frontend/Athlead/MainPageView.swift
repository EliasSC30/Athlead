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
        }.onAppear {
            Task {
                await loadSportFests()
            }
        }
    }
    
    
    private func loadSportFests() async {
        isLoading = false
        errorMessage = nil
        
        let url = URL(string: "\(apiURL)/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            default:
                break
            }
        } catch {
            print("Error during request: \(error)")
        }
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
