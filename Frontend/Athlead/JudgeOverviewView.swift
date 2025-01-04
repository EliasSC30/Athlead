//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI

struct JudgeOverviewView: View {
    @State var contests: [ContestForJudge] = [];
    @State private var isLoading = false;
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading contests...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    JudgeContestsView(contests: contests)
                }
            }.navigationTitle("My Contests")
        }.onAppear(perform: loadContests)
    }
    
    func loadContests() {
        isLoading = true;
        errorMessage = nil;
        fetch("contests/judge/mycontests", ContestForJudgeResponse.self) { result in
            switch result {
            case .success(let myData):
                contests = myData.data;
            case .failure(let error):
                errorMessage = error.localizedDescription;
            }
            isLoading = false;
        }
    }
}
