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
                                    SportfestCard(isNextSportfest: allSportFests.firstIndex(where: { $0.id == sportfest.id }) == 0, sportfest: sportfest)
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
    var isNextSportfest: Bool
    let sportfest: SportfestData
    @State private var timerValue: Int = 45 * 60 // 45 minutes in seconds
    @State private var timerText: String = "45:00"
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let contestStates: [String] = ["checkmark.circle.fill", "x.circle.fill", "questionmark.circle.fill"]
    
    @State private var userContests: [ContestData] = []
    
    let currentTime = Date()
    
    @State private var nextContest: ContestData?
    
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
                if nextContest != nil {
                    VStack(alignment: .trailing) {
                        Text("\(nextContest!.ct_details_name) in")
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
                
                ForEach(userContests, id: \.self) { contest in
                    HStack {
                        if stringToDate(contest.ct_details_end) < currentTime {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "x.circle.fill")
                                .foregroundColor(.red)
                        }
                        Text(contest.ct_details_name)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear(perform: fetchContests)
    }
    
    // Timer functionality
    func formatTime(_ totalSeconds: Int) -> String {
        if totalSeconds >= 30 * 24 * 60 * 60 { // More than a month
            let months = totalSeconds / (30 * 24 * 60 * 60)
            let remainingDays = (totalSeconds % (30 * 24 * 60 * 60)) / (24 * 60 * 60)
            return remainingDays == 0 ? "\(months)m" : "\(months)m \(remainingDays)d"
        } else if totalSeconds >= 7 * 24 * 60 * 60 { // More than a week
            let weeks = totalSeconds / (7 * 24 * 60 * 60)
            let remainingDays = (totalSeconds % (7 * 24 * 60 * 60)) / (24 * 60 * 60)
            return remainingDays == 0 ? "\(weeks)w" : "\(weeks)w \(remainingDays)d"
        } else if totalSeconds >= 24 * 60 * 60 { // More than a day
            let days = totalSeconds / (24 * 60 * 60)
            return "\(days)d"
        } else if totalSeconds >= 60 * 60 { // More than an hour
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return String(format: "%dh %02dm", hours, minutes)
        } else { // Less than an hour
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    
    
    func stringToDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: string) ?? Date()
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
    
    func fetchContests() {
        let uC = sportfest.cts_wf.filter { $0.participates == true }
        let dispatchGroup = DispatchGroup()
        var fetchedContests: [ContestData] = []

        for contest in uC {
            let contestId = contest.contest_id
            dispatchGroup.enter()
            fetch("contests/\(contestId)", ContestResponse.self) { result in
                switch result {
                case .success(let resp):
                    DispatchQueue.main.async {
                        fetchedContests.append(resp.data)
                    }
                case .failure(let error):
                    print(error)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            userContests = fetchedContests.sorted { $0.ct_details_start < $1.ct_details_start }
            if let firstContest = userContests.first {
                nextContest = firstContest
                setTimerVariables()
            }
        }
    }
    
    func setTimerVariables() {
        if nextContest == nil {
            return
        }
        
        let nextContestDate = stringToDate(nextContest!.ct_details_start)

        let timeDifference = nextContestDate.timeIntervalSince(currentTime)

        if timeDifference <= 0 {
            // If the contest has already started or the time difference is negative
            timerValue = -1
            timerText = "Started"
        } else if timeDifference < 24 * 60 * 60 { // Less than 24 hours
            timerValue = Int(timeDifference)
            let hours = Int(timeDifference) / 3600
            let minutes = (Int(timeDifference) % 3600) / 60
            let seconds = Int(timeDifference) % 60
            timerText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else if timeDifference <= 7 * 24 * 60 * 60 { // Between 1 and 7 days
            let days = Int(timeDifference) / (24 * 60 * 60)
            timerValue = -1
            timerText = "\(days)d"
        } else if timeDifference <= 30 * 24 * 60 * 60 { // Between 7 days and 1 month
            let totalDays = Int(timeDifference) / (24 * 60 * 60)
            let weeks = totalDays / 7
            let days = totalDays % 7

            if days == 0 {
                timerText = "\(weeks)w"
            } else {
                timerText = "\(weeks)w \(days)d"
            }

            timerValue = -1
        } else { // More than 1 month
            let totalDays = Int(timeDifference) / (24 * 60 * 60)
            let months = totalDays / 30
            let remainingDays = totalDays % 30

            if remainingDays == 0 {
                timerText = "\(months)m"
            } else {
                timerText = "\(months)m \(remainingDays)d"
            }

            timerValue = -1
        }
        
    }

    
}
