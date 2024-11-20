//
//  EventDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI

struct EventDetailView: View {
    let eventName: String
    let date: String

    var body: some View {
        VStack {
            Text(eventName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Datum: \(date)")
                .font(.title2)
                .padding()

            Spacer()
        }
        .navigationTitle("Wettkampf Details")
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(eventName: "Bundesjugendspiele", date: "22. November 2024")
    }
}
