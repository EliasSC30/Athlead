//
//  EventScheduleView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 07.01.25.
//


import SwiftUI

struct EventScheduleView: View {
    @State private var sportfests: [Date: [String]] = [:]
    @State private var selectedDate: Date? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(generateDatesForNextMonths(), id: \ .self) { date in
                        ZStack {
                            if let events = sportfests[date], !events.isEmpty {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                            } else {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 50, height: 50)
                            }
                            Text(dayString(from: date))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()

                if let selectedDate = selectedDate, let events = sportfests[selectedDate], !events.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Events on \(formattedDate(selectedDate)):")
                            .font(.headline)
                            .padding(.vertical)

                        ForEach(events, id: \ .self) { event in
                            Text(event)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding()
                } else if selectedDate != nil {
                    Text("No events for the selected day.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .onAppear(perform: loadDummyData)
            .navigationTitle("Upcoming Sportfests")
        }
    }

    private func loadDummyData() {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        let startDate = formatter.date(from: "2025/01/01")!
        let endDate = formatter.date(from: "2025/03/31")!

        var currentDate = startDate

        while currentDate <= endDate {
            let dayEvents: [String]
            if calendar.component(.weekday, from: currentDate) == 6 { // Highlight Saturdays
                dayEvents = ["Soccer Match", "Basketball Tournament"]
            } else {
                dayEvents = []
            }

            sportfests[calendar.startOfDay(for: currentDate)] = dayEvents
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }

    private func generateDatesForNextMonths() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .month, value: 2, to: startDate)!

        var dates: [Date] = []
        var currentDate = startDate

        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
