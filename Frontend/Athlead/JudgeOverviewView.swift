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
        NavigationView {
            VStack {
                JudgeContestsView(competitions: contests)
            }
        }.onAppear {
            let urlString = "\(apiURL)/contests/judge/mycontests"
            let cookies = [
                "Token": """
                akafbmoipljlmeilmbkiclgffffocdpgdeghnhabboghoffdaohijebiakalknnalipaedlkhegfaonjgbaiihcndeeolhmmecpcaljfjpnicckjjmddooohpadkhghcmfenaaaa
                """,
            ]

            fetchData(from: urlString, ofType: ContestForJudgeResponse.self, cookies: cookies, method: "GET") { result in
                switch result {
                case .success(let myData):
                    print("Fetched Data: \(myData)")
                    contests = myData.data;
                case .failure(let error):
                    print("Error fetching data: \(error)")
                }
            }

        };
    }
}
