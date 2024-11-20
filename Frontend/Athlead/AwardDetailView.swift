//
//  AwardDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI

struct AwardDetailView: View {
    let awardName: String
    let year: Int
    let medalType: MedalType

    var body: some View {
        VStack {
            Text(awardName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Jahr: \(year)")
                .font(.title2)
                .padding()

            Image(systemName: medalType == .gold ? "medal" :
                                medalType == .silver ? "medal" :
                                "medal")
                .foregroundColor(medalType == .gold ? .yellow :
                                medalType == .silver ? .gray :
                                .brown)
                .font(.system(size: 100))
                .padding()

            Spacer()
        }
        .navigationTitle("Auszeichnung")
    }
}

struct AwardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AwardDetailView(awardName: "Goldmedaille - Sprint", year: 2024, medalType: .gold)
    }
}
