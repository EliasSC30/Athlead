//
//  JudgeContestView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 29.11.24.
//

import SwiftUI

struct JudgeContestsView: View {
    let contests: [ContestForJudge]
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                if contests.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.red)
                            .padding(.bottom, 16)
                        
                        Text("No Competitions Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primary)
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                        
                        Text("It seems like you don’t have any competitions to judge at the moment.")
                            .font(.body)
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding()
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 32)
                } else {
                    List {
                        ForEach(contests.indices, id: \.self) { index in
                            NavigationLink(destination: JudgeContestView(contest: contests[index])) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(contests[index].ct_name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Tap to review details")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}

struct JudgeContestView: View {
    let contest: ContestForJudge
    @State private var participants: [Participant] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading participants for contest...")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView()
                        .padding(.horizontal, 16)
                    
                    NavigationButton(
                        title: "Ergebnisse eintragen",
                        destination: JudgeEntryView(contest: contest),
                        systemImage: "pencil"
                    )
                    .padding(.horizontal, 16)
                    
                    NavigationButton(
                        title: "Teilnehmer",
                        destination: JudgeParticipants(participants: $participants),
                        systemImage: "person.2.fill"
                    )
                    .padding(.horizontal, 16)
                    
                    NavigationButton(
                        title: "Checkin Teilnehmer",
                        destination: JudgeScanView(),
                        systemImage: "qrcode.viewfinder"
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding(.top, 16)
            }
        }.onAppear {
            fetchParticipants()
        }
    }
    
    // MARK: - Components
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(contest.ct_name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Manage participants, entries, and check-ins for the contest.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 16)
    }
    
    private func NavigationButton(title: String, destination: some View, systemImage: String) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Data Fetching
    private func fetchParticipants() {
        isLoading = true
        errorMessage = nil
        fetch("contests/\(contest.ct_id)/participants", ParticipantsForJudge.self) { result in
            switch result {
            case .success(let participantsResult):
                participants = participantsResult.data
                isLoading = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}



struct JudgeParticipants: View {
    @Binding var participants: [Participant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if participants.isEmpty {
                VStack {
                    Image(systemName: "person.3.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.bottom, 16)
                    
                    Text("No Participants")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("It looks like no participants have registered yet.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(24)
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(participants) { participant in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(participant.f_name) \(participant.l_name)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if participant.pics == 1 {
                                    Text("Allowed to take photos")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Not allowed to take photos")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: participant.pics == 1 ? "camera" : "camera.slash")
                                .foregroundColor(participant.pics == 1 ? .blue : .red.opacity(0.6))
                                .font(.title3)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .background(Color(UIColor.systemBackground))
        .navigationTitle("\(participants.count) Participants")
    }
}


struct JudgeEntryView: View {
    @State var contest: ContestForJudge
    @State private var contestResults: [ContestResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMEssage: String?
    
    // Variables for editing
    @State private var startingInput: String = ""
    @State private var editingIndex: Int?
    @State private var isEditing: Bool = false
    @State private var updatedInput: String = ""
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading contest results...")
            } else if let errorMessage = errorMEssage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView()
                        .padding(.horizontal, 16)
                    
                    if !contestResults.isEmpty {
                        ResultsListView()
                            .padding(.horizontal, 16)
                    } else {
                        EmptyStateView()
                            .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                }
                .padding(.top, 16)
            }
        }
        .onAppear(perform: fetchContestResults)
        .sheet(isPresented: $isEditing) {
            EditEntrySheet()
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(contest.ct_name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Enter and manage results for participants in \(contest.ct_name).")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    @ViewBuilder
    private func ResultsListView() -> some View {
        List {
            Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                ForEach(contestResults.indices, id: \.self) { index in
                    HStack {
                        Text(formattedString(contestResults[index]))
                            .padding(.leading)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Edit button
                        Button(action: {
                            // Set up for editing
                            editingIndex = index
                            startingInput = contestResults[index].value.map { String($0) } ?? ""
                            updatedInput = startingInput
                            isEditing = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                                .padding(.trailing)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color.gray.opacity(0.6))
            
            Text("Keine Einträge bisher")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start adding results by selecting a participant.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Edit Entry Sheet
    
    @ViewBuilder
    private func EditEntrySheet() -> some View {
        VStack(spacing: 20) {
            Text("Edit Entry")
                .font(.title)
                .fontWeight(.bold)
            
            if let index = editingIndex {
                Text("Editing: \(contestResults[index].p_firstname) \(contestResults[index].p_lastname)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                TextField("Enter new value", text: $updatedInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Confirm") {
                        if let newValue = Double(updatedInput) {
                            print("Old Value: \(startingInput)")
                            print("New Value: \(updatedInput)")
                            contestResults[index].value = newValue
                        }
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Cancel") {
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding()
    }

    
    // MARK: - Helpers
    
    private func formattedString(_ ctr: ContestResult) -> String {
        var result = "\(ctr.p_firstname.prefix(1)). \(ctr.p_lastname) "
        if let value = ctr.value {
            result += "\(floatToString(value)) \(contest.ct_unit.lowercased())"
        } else {
            result += "N/A \(contest.ct_unit.lowercased())"
        }
        return result
    }
    
    private func floatToString(_ val: Float64) -> String {
        return String(format: "%.2f", val)
    }
    
    // MARK: - Data Management
    
    private func fetchContestResults() {
        isLoading = true
        errorMEssage = nil
        fetch("contests/\(contest.ct_id)/contestresults", ContestResultsResponse.self) { response in
            switch response {
            case .success(let resp):
                contestResults = resp.data
                isLoading = false
            case .failure(let error):
                print("Error fetching contest results: \(error)")
                errorMEssage = error.localizedDescription
                isLoading = false
            }
        }
    }
}



struct ResultEntry: View {
    let contest: ContestForJudge
    @Binding var startingInput: String
    let nameOfParticipant: String
    var onNewResult: (Float64) -> Void
    
    func enterUnitText(_ unit: String) -> String {
        switch unit.lowercased() {
        case "m": return "Enter length in meters"
        case "s": return "Enter time in seconds"
        case "kg": return "Enter weight in kilograms"
        default: return "Unknown unit"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter Data")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)
            
            Text(nameOfParticipant)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            FloatInput(
                onNewResult: onNewResult,
                entryTitle: enterUnitText(contest.ct_unit),
                startingInput: $startingInput
            )
        }
    }
}


struct FloatInput: View {
    var onNewResult: (Float64) -> Void
    let entryTitle: String
    @State private var value: Float64? = nil
    @Binding var startingInput: String
    
    @State private var valueInput: String = ""
    @State private var isValid: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(entryTitle)
                .font(.body)
                .foregroundColor(.secondary)
            
            TextField("Enter value", text: $valueInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .foregroundColor(isValid ? .primary : .red)
                .onAppear { valueInput = startingInput }
                .onChange(of: startingInput) { newValue in
                    valueInput = newValue
                }
                .onChange(of: valueInput) { newValue in
                    isValid = validateInput(input: newValue)
                    if isValid {
                        value = Float64(newValue.replacingOccurrences(of: ",", with: "."))
                    }
                }
            
            Button(action: {
                guard let validValue = value, isValid else { return }
                onNewResult(validValue)
                valueInput = ""
            }) {
                Text("Confirm")
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? Color.blue : Color.gray.opacity(0.5))
                    .cornerRadius(8)
            }
            .disabled(!isValid || value == nil)
        }
        .padding(16)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func validateInput(input: String) -> Bool {
        let sanitizedInput = input.replacingOccurrences(of: ",", with: ".")
        return Float64(sanitizedInput) != nil
    }
}




