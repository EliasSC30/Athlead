//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI

struct JudgeOverviewView: View {
    @State var contests: [ContestForJudge] = [];
    var body: some View {
        VStack {
                JudgeContestsView(contests: contests)
            }.onAppear {

            fetch("\(apiURL)/contests/judge/mycontests", ContestForJudgeResponse.self) { result in
                switch result {
                case .success(let myData):
                    contests = myData.data;
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }
        };
    }
}
