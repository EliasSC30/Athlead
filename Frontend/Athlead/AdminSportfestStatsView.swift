//
//  AdminSportfestStatsView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.01.25.
//

import SwiftUI

struct AdminSportfestStatsView: View {
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @State private var sportfestsMaster = [];
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading sportfest stats...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
            }
        }.onAppear {
            loadData()
        }
    }
    
    func loadData() {
        fetch("sportfests", SportFestsResponse.self) { result in
            switch result {
            case .success(let myData):
                print(myData.data)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
