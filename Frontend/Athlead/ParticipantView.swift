//
//  ParticipantView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 28.12.24.
//
import SwiftUI

struct ParticipantView: View {
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var allSportFests: [SportfestData] = []
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Preparing your page...")
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(allSportFests) { sportfest in
                                NavigationLink(destination: SportfestParticipantDetailView(sportfest: sportfest)) {
                                    SportfestCard(sportfest: sportfest)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Sportfests")
                }
            }
        }
        .onAppear(perform: loadData)
    }
    
    func loadData() {
        isLoading = true
        
        fetch("sportfests", SportFestsResponse.self) { result in
            switch result {
            case .success(let resp):
                allSportFests = resp.data
                allSportFests.sort(by: { $0.details_start < $1.details_start })
            case .failure(let error):
                errorMessage = error.localizedDescription
                print(error)
            }
            isLoading = false
        }
    }
}

// Sportfest Card View
struct SportfestCard: View {
    let sportfest: SportfestData
    @State private var timerValue: Int = 45 * 60 // 45 minutes in seconds
    @State private var timerText: String = "45:00"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let contestStates: [String] = ["checkmark.circle.fill", "x.circle.fill", "questionmark.circle.fill"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sportfest Name as the Title
            HStack {
                Text(sportfest.details_name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Timer Section
                VStack(alignment: .trailing) {
                    Text("Weitsprung in")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(timerText)
                        .font(.headline)
                        .foregroundColor(.red)
                        .onReceive(timer) { _ in
                            if timerValue > 0 {
                                timerValue -= 1
                                timerText = formatTime(timerValue)
                            }
                        }
                    Text("Location: \(sportfest.location_name)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Information Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Start: \(formatDate(sportfest.details_start))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    Text("End: \(formatDate(sportfest.details_end))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                    Text("Location: \(sportfest.location_name)")
                        .font(.subheadline)
                }
                
                Divider() // Visual separation
                
                Text("Contests:")
                    .font(.headline)
                
                ForEach(["Weitsprung", "100m Lauf", "Speerwurf"], id: \.self) { contest in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(contest)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Timer functionality
    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .full
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}


// Sportfest Detail View
struct SportfestParticipantDetailView: View {
    let sportfest: SportfestData
    
    var body: some View {
        VStack(spacing: 20) {
            Text(sportfest.details_name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Start: \(formatDate(sportfest.details_start))")
                .font(.title3)
            Text("End: \(formatDate(sportfest.details_end))")
                .font(.title3)
            
            Spacer()
        }
        .navigationTitle("Details")
        .padding()
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
