//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI

struct JudgeOverviewView: View {
    @State var contests: [ContestForJudge] = [];
    @State private var isFetchingContests = true;
    
    var body: some View {
        VStack {
            if isFetchingContests {
                Text("Loading contests..")
            } else {
                JudgeContestsView(isFetchingContests: $isFetchingContests, contests: $contests)
            }
            }.onAppear {
                isFetchingContests = true;
                fetch("contests/judge/mycontests", ContestForJudgeResponse.self) { result in
                    switch result {
                    case .success(let myData):
                        contests = myData.data;
                    case .failure(let error):
                        print("Error fetching data: \(error)")
                    }
                }
                isFetchingContests = false;
        };
    }
}
