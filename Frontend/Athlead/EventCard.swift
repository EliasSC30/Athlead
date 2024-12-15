//
//  EventCard.swift
//  Athlead
//
//  Created by Wichmann, Jan on 13.12.24.
//

import  SwiftUI

struct EventCard: View {
    let eventName: String
    let sportfestID: String
    
    struct DummyContest: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let date: Date
    }
    
    private let subContests = [
        DummyContest(name: "Sprint", date: Date()),
        DummyContest(name: "Long Jump", date: Date()),
        DummyContest(name: "High Jump", date: Date())
    ]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                NavigationLink(destination: SportfestOverview(sportfestID: sportfestID)
                ){
                    Text(eventName)
                        .font(.headline)
                    Spacer()
                }
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            
            if isExpanded {
                ForEach(subContests) { subContest in
                    SubContestView(subContest: subContest)
                }
            }
        }
        .padding()
        .background(
            Color.white
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

struct SubContestView: View {
    let subContest: EventCard.DummyContest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            NavigationLink(destination: ContestDetailView()) {
                HStack {
                    Text(subContest.name)
                        .font(.subheadline)
                    Spacer()
                    Text(subContest.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Divider()
        }
        .padding(.leading, 20)
    }
}
