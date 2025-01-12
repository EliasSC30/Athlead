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
                        Text(helper.description ?? "No description available.")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if helper.id == userID {
                            Picker("Your Contribution Type", selection: Binding(
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
                            .pickerStyle(SegmentedPickerStyle())
                        } else {
                            Text("Role: \(helper.roleAsContributionType.rawValue)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
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
        if let index = helpers.firstIndex(where: { $0.id == helperID }) {
            print("Updated role for helper \(helperID) to \(newType.rawValue)")
        }

        print("Updating helper \(helperID) to type \(newType.rawValue)")
        // TODO: Implement backend call for updating the role
    }
}

// Extension to map Helper role to contribution types
extension Helper {
    var roleAsContributionType: HelperContributationView.HelperContributationTypes {
        return HelperContributationView.HelperContributationTypes(rawValue: self.role) ?? .zusaetzlicheAufgabenFuerHelfer
    }
}
