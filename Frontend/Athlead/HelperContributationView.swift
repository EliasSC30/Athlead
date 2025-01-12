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
    @State private var helpers: [Helper] = [] // Array to hold fetched helpers
    @State private var userID: String = User!.ID // Current user's ID

    enum HelperContributationTypes: String, CaseIterable, Identifiable {
        case vorbereitungDesWettkampfs = "Vorbereitung des Wettkampfs"
        case betreuungDerAthleten = "Betreuung der Athleten"
        case durchfuehrungDesWettkampfs = "Durchführung des Wettkampfs"
        case ueberwachungDerRegeln = "Überwachung der Regeln"
        case dokumentationDerErgebnisse = "Dokumentation der Ergebnisse"
        case zusaetzlicheAufgabenFuerHelfer = "Zusätzliche Aufgaben für Helfer"

        var id: String { self.rawValue }
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
                List(helpers, id: \.id) { helper in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(helper.first_name) \(helper.last_name)")
                            .font(.headline)

                        if helper.id == userID {
                            Picker("Task: ", selection: Binding(
                                get: {
                                    helper.roleAsContributionType
                                },
                                set: { newType in
                                    updateOwnContributation(helperID: helper.id, newType: newType)
                                }
                            )) {
                                ForEach(HelperContributationTypes.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text("Contribution: \(helper.roleAsContributionType.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear(perform: fetchAllHelpers)
        .navigationTitle("Helper Contributions")
    }

    func fetchAllHelpers() {
        isLoading = true
        fetch("contests/\(contest.ct_id)/helpers", HelperResponse.self) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    self.helpers = response.helper
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateOwnContributation(helperID: String, newType: HelperContributationTypes) {
        helpers = helpers.map { helper in
            if helper.id == helperID {
                var newHelper = helper
                newHelper.description = newType.rawValue
                return newHelper
            } else {
                return helper
                
            }
        }
        
        let hC = HelperPatchContribution(description: newType.rawValue)
        
        
        fetch("contests/\(contest.ct_id)/helper/\(helperID)", HelperPatchResponse.self, "PATCH", nil, hC) { result in
            switch result {
            case .success( _):
                print("Successfully updated helper \(helperID) to type \(newType.rawValue)")
            case .failure(let error):
                print("Failed to update helper \(helperID) to type \(newType.rawValue): \(error.localizedDescription)")
            }
        }
    }
}

// Extension to map Helper role to contribution types
extension Helper {
    var roleAsContributionType: HelperContributationView.HelperContributationTypes {
        return HelperContributationView.HelperContributationTypes(rawValue: self.description ?? "") ?? .zusaetzlicheAufgabenFuerHelfer
    }
}
