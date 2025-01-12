//
//  HelperContributationView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 12.01.25.
//

import SwiftUI

struct HelperContributationView: View {
    let contest: ContestForJudge
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    
    enum HelperContributationTypes: String, CaseIterable {
        case vorbereitungDesWettkampfs
        case betreuungDerAthleten
        case durchfuehrungDesWettkampfs
        case ueberwachungDerRegeln
        case dokumentationDerErgebnisse
        case zusaetzlicheAufgabenFuerHelfer
    }
        
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading helper data...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack {
                    Text("Hallo, ich bin ein Helfer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                }
            }
        }.onAppear(perform: fetchAllHelpers)
    }
    
    func fetchAllHelpers() {
        print(contest)
        fetch("contests/\(contest.ct_id)/helpers", HelperResponse.self) { result in
            switch result {
            case .success(let helpers):
                print(helpers)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateOwnContributation() {
    }
}
