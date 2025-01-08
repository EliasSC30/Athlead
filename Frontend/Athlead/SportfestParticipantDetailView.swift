//
//  SportfestParticipantDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 08.01.25.
//
import SwiftUI

struct SportfestParticipantDetailView: View {
    let sportfest: SportfestData
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfest details...")
            } else if let errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
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
        }
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

extension SportfestParticipantDetailView {
    func openAndConsumeWebSocketConnection() async {
        //let connection: WebSocketConnection<IncomingMessage, OutgoingMessage> = await WebSocketConnection.connect(to: "ws://45.81.234.175:8000/ws/id")
    }
}
