//
//  BestSportDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI

struct BestSportDetailView: View {
    let sportName: String
    let score: String

    var body: some View {
        VStack {
            Text("Deine beste Sportart")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text(sportName)
                .font(.title)
                .padding()

            Text("Bestleistung: \(score)")
                .font(.title2)
                .padding()

            Spacer()
        }
        .navigationTitle("Beste Sportart")
    }
}

struct BestSportDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BestSportDetailView(sportName: "Weitwurf", score: "85 Meter")
    }
}
