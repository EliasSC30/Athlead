//
//  SportfestParticipantContestDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 08.01.25.
//
import SwiftUI
import MapKit
import CoreLocation
import Foundation

struct SportfestParticipantContestDetailView: View {
    let contest: ContestData
    
    @Environment(\.webSocketConnectionFactory) private var webSocketConnectionFactory: WebSocketConnectionFactory

    @State private var webSocketConnectionTask: Task<Void, Never>? = nil
    @State private var connection: WebSocketConnection<WebSocketMessageRecieve>? = nil
    
    @State private var results: [ContestResult] = []
    @State private var rankedResults: [(ContestResult, Int)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var isLive: Bool = false
    @State private var showMap: Bool = false
    
    @State private var rankingAscending: Bool = false
    @State private var client: WebSocketClient = WebSocketClient();
    @State private var isConnected: Bool = false;
    
    var body: some View {
        ScrollView {
            Group {
                if isLoading {
                    ProgressView("Loading results...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    ContestDetails(contest: contest, showMap: $showMap)
                    
                    Divider()
                        .padding()
                    
                    VStack(spacing: 15) {
                        ResultsHeaderView(isLive: isLive)
                            .padding(.top, 10)
                        
                        ForEach(rankedResults, id: \.0.id) { (result, rank) in
                            ResultCard(result: result, rank: rank, isLoggedInUser: result.p_id == User!.ID)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(contest.ct_details_name)")
        .onAppear {
            isLive = false
            webSocketConnectionTask?.cancel()

            webSocketConnectionTask = Task {
                await openAndConsumeWebSocketConnection()
                let startDate = stringToDate(contest.ct_details_start)
                let endDate = stringToDate(contest.ct_details_end)
                
                let now = Date()
                
                isLive = now >= startDate && now <= endDate  && isConnected
            }
            
            loadResults()
        }
        .refreshable {
            isLive = false
            webSocketConnectionTask?.cancel()

            webSocketConnectionTask = Task {
                await openAndConsumeWebSocketConnection()
                let startDate = stringToDate(contest.ct_details_start)
                let endDate = stringToDate(contest.ct_details_end)
                
                let now = Date()
                
                isLive = now >= startDate && now <= endDate  && isConnected
            }
            
            loadResults()
        }
        .sheet(isPresented: $showMap) {
            ContestMapView(contest: contest, showMapSheet: $showMap)
        }
    }
    
    func loadResults() {
        isLoading = true
        errorMessage = nil
        
        fetch("contests/\(contest.id)/contestresults", ContestResultsResponse.self) { result in
            switch result {
            case .success(let resp):
                results = resp.data
                rankingAscending = resp.ascending == "ASCENDING"
                calculateRankings()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func calculateRankings() {
        let scoredResults = results.filter { $0.value != nil }
        let noScoreResults = results.filter { $0.value == nil }
        
        
        var sortedScoredResults: [ContestResult] = []
        if rankingAscending {
            sortedScoredResults = scoredResults.sorted { ($0.value ?? 0) < ($1.value ?? 0) }
        } else {
            sortedScoredResults = scoredResults.sorted { ($0.value ?? 0) > ($1.value ?? 0) }
        }
        
        var rank = 1
        var lastValue: Double? = nil
        var ranks: [(ContestResult, Int)] = []
        
        for (index, result) in sortedScoredResults.enumerated() {
            if let value = result.value, value != lastValue {
                rank = index + 1
            }
            lastValue = result.value
            ranks.append((result, rank))
        }
        
        let noScoreRank = scoredResults.count + 1
        
        for result in noScoreResults {
            ranks.append((result, noScoreRank))
        }
        
        rankedResults = ranks
    }
    
    
    
    
    func stringToDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: string) ?? Date()
    }
}


struct ResultCard: View {
    let result: ContestResult
    let rank: Int
    let isLoggedInUser: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(rank). \(result.p_firstname) \(result.p_lastname)")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let value = result.value, let unit = result.unit {
                    Text(String(format: "%.1f %@", value, unit))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(6)
                        .background(Color.yellow)
                        .cornerRadius(10)
                } else {
                    Text("No Score")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(10)
                }
            }
            
            HStack(spacing: 10) {
                if let grade = result.p_grade {
                    Label("Grade \(grade)", systemImage: "graduationcap.fill")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                
                if let birthYear = result.p_birth_year {
                    Label("Born \(birthYear)", systemImage: "calendar")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(UIColor.separator), lineWidth: 1)
        )
    }
}

extension SportfestParticipantContestDetailView {
    
    @MainActor func openAndConsumeWebSocketConnection() async {
        let url = URL(string: "ws://45.81.234.175:8000/ws/\(contest.ct_id)")!

         // Close any existing WebSocketConnection
         if let connection {
             connection.close()
         }

         let connection: WebSocketConnection<WebSocketMessageRecieve> = webSocketConnectionFactory.open(url: url)

         self.connection = connection

         do {
             // Start consuming IncomingMessages
             for try await message in connection.receive() {
                 print("Received message:", message)
             }

             print("IncomingMessage stream ended")
         } catch {
             print("Error receiving messages:", error)
         }
     }
    
}





struct ContestDetails: View {
    let contest: ContestData
    @Binding var showMap: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Section
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                Text("Contest Details")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Location Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text("Location:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text(contest.ct_location_name)
                Text("\(contest.ct_street) \(contest.ct_streetnumber)")
                Text("\(contest.ct_zipcode) \(contest.ct_city)")
                // Open Map Button
                Button(action: {
                    showMap.toggle()
                }) {
                    Text("Open Map")
                        .foregroundColor(.blue)
                        .font(.headline)
                        .padding(.top, 8)
                }
            }
            
            Divider()
            
            // Contact Person Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                    Text("Contact Person:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text("\(contest.ct_cp_firstname) \(contest.ct_cp_lastname)")
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                    Text("Phone: \(contest.ct_cp_phone)")
                }
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.orange)
                    Text("Email: \(contest.ct_cp_email)")
                }
            }
            
            Divider()
            
            // Event Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                    Text("Event Details:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                    Text("Start: \(formatDate(contest.ct_details_start))")
                }
                HStack {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                    Text("End: \(formatDate(contest.ct_details_end))")
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
struct ResultsHeaderView: View {
    let isLive: Bool
    
    var body: some View {
        HStack {
            // Title on the left
            Text("Results")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Live ticker on the right
            LiveIndicator(isLive: isLive)
        }
        .padding()
    }
}

struct LiveIndicator: View {
    let isLive: Bool
    @State private var pulse: Bool = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(isLive ? Color.green : Color.red)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(isLive ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 4)
                        .scaleEffect(pulse ? 1.2 : 1.0)
                        .opacity(pulse ? 0.8 : 1.0)
                )
                .onAppear {
                    // Start pulsing animation
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        pulse.toggle()
                    }
                }
            
            Text(isLive ? "Live" : "Offline")
                .font(.headline)
                .foregroundColor(isLive ? .green : .red)
        }
    }
}



struct ContestMapView: View {
    let contest: ContestData
    
    @Binding var showMapSheet: Bool
    @State private var sportfestCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 0.0,
        longitude: 0.0
    )
    
    var body: some View {
        Map {
            Marker(contest.ct_details_name, systemImage: "figure.wave", coordinate: sportfestCoordinate)
        }.onAppear(perform: loadCoordinate)
            .mapStyle(.standard(elevation: .realistic))
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    MapButtons(coordinate: sportfestCoordinate, showMapSheet: $showMapSheet)
                        .padding(.top)
                    Spacer()
                }.background(.thinMaterial)
            }
    }
    
    
    func loadCoordinate() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString("\(contest.ct_street) \(contest.ct_streetnumber), \(contest.ct_zipcode) \(contest.ct_city)", completionHandler: {
            placemarks, error in
            let placemark = placemarks?.first
            let lat = placemark?.location?.coordinate.latitude
            let lon = placemark?.location?.coordinate.longitude
            sportfestCoordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        })
    }
}
