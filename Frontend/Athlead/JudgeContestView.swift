//
//  JudgeContestView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 29.11.24.
//

import SwiftUI

extension String {
    func truncated(to length: Int) -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            return self[self.startIndex..<endIndex] + "..."
        } else {
            return self
        }
    }
}

struct JudgeContestsView : View {
    let contests: [ContestForJudge]
    
    var body: some View {
        NavigationStack {
            VStack {
                if contests.isEmpty {
                    Text("You have no competitions")
                        .padding()
                        .background(Color.white)
                        .shadow(radius: 5.0)
                } else {
                    ForEach(contests.indices, id: \.self) { index in
                        NavigationLink(destination: JudgeContestView(contest: contests[index])) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contests[index].ct_name)
                                        .font(.headline)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                            .padding(.horizontal)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct JudgeContestView : View {
    let contest: ContestForJudge
    @State var participants: [Participant] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: JudgeEntryView(contest: contest)){
                    Text("Ergebnisse eintragen")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
                
                NavigationLink(destination: JudgeParticipants(participants: $participants)){
                    Text("Teilnehmer")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
                
                NavigationLink(destination: JudgeScanView()){
                    Text("Checkin Teilnehmer")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
            }
        }.onAppear{
            fetch(from: "\(apiURL)/contests/\(contest.ct_id)/participants", ofType: ParticipantsForJudge.self){ result in
                switch result {
                case .success(let participantsResult): participants = participantsResult.data;
                case .failure(let err): print(err);
                }
            }
        }
    }
}

struct JudgeParticipants : View {
    @Binding var participants: [Participant]
    
    var body: some View {
        VStack {
            if participants.isEmpty{
                Text("Bisher keine Teilnehmer")
            } else {
                ForEach(participants){ participant in
                    HStack {
                        Text("\(participant.f_name) \(participant.l_name)")
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
    }
}

struct JudgeEntryView : View {
    let contest : ContestForJudge
    // Local results that update the results in the store when leaving
    @State private var contestResults: [ContestResult] = []

    // Variables for adding
    @State private var newParticipantName: String = ""
    @State private var newMetric: Metric = Metric()
    
    // Variables for editing
    @State private var showEditSheet: Bool = false
    @State private var nameToEdit: String = ""
    @State private var metricToEdit: Metric = Metric()
    @State private var editingIndex: Int = 0
    
    func getMetricField(contestResult: ContestResult, unit: String) -> Float64 {
        switch unit.lowercased() {
        case "m": return contestResult.length.unsafelyUnwrapped;
        case "s": return contestResult.time.unsafelyUnwrapped;
        case "kg": return contestResult.weight.unsafelyUnwrapped;
        default: return contestResult.time.unsafelyUnwrapped;
        }
    }
    
    var body: some View {
        VStack {
            ResultEntry(
                contest: contest,
                onNewResult: {
                    newParticipantName = ""
                    newMetric = Metric()
                },
                name: $newParticipantName,
                metric: $newMetric,
                isEdit: false)
            .padding()
            
            if(!contestResults.isEmpty) {
                List {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        ForEach(contestResults.indices, id: \.self) { index in
                            HStack {
                                Text("\(contestResults[index].p_firstname) \(contestResults[index].p_lastname) \(getMetricField(contestResult: contestResults[index], unit: contest.ct_unit), specifier: "%.2f")\(contest.ct_unit.lowercased())")
                                                                        .padding(.leading)
                                Spacer()

                                // Edit button
                                Button(action: {
                                    self.editingIndex = index
                    
                                    self.nameToEdit = self.contestResults[index].p_firstname
                                    self.showEditSheet = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title)
                                        .padding(.trailing)
                                }
                            }
                        }
                        .onDelete(perform: delete) // Enable swipe-to-delete functionality
                    }
                } // List
                .padding(.top, 5)
                .foregroundColor(.primary)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .background(Color.white)
                .scrollContentBackground(.hidden)
            } else { // List is empty
                Text("Keine Einträge bisher").bold().padding(.vertical, 10)
                
            }
        } // VStack
        .onDisappear(){
            // We only write to the store when we leave
            STORE[contest.ct_name] = contestResults
            
        }
        .onAppear() {
            if HasInternetConnection {
                fetch(from: "\(apiURL)/contests/\(contest.ct_id)/contestresults", ofType: ContestResultsResponse.self){
                    response in
                    switch response {
                    case .success(let resp):
                        contestResults = resp.data;
                    case .failure(let err): print("Error when fetching contestresults: ", err);
                    }
                }
            } else {
                if(STORE[contest.ct_name]) != nil { contestResults = STORE[contest.ct_name]! }
            }
            
        }
        .sheet(isPresented: $showEditSheet) {
            EditResultView(contest: contest,
                           nameToEdit: $nameToEdit,
                           metricToEdit: $metricToEdit,
                           onNewResult: {
                                // Save the edited result back to the list
                                if !contestResults.isEmpty {
                                    
                                }

                                showEditSheet = false
                            })
        }
        .padding(.top, 10)
    }
        

    // Handle deletion via swipe-to-delete
    private func delete(at offsets: IndexSet) {
        contestResults.remove(atOffsets: offsets)
    }
}

struct EditResultView: View {
    let contest: ContestForJudge
    @Binding var nameToEdit : String
    @Binding var metricToEdit: Metric
    var onNewResult: () -> Void
    
    var body: some View {
            VStack {
                Text("Ändere den Eintrag").font(.title).bold().padding(.top, 10).padding(.bottom, 15)

                ResultEntry(contest: contest,
                            onNewResult : onNewResult,
                            name: $nameToEdit,
                            metric : $metricToEdit,
                            isEdit: true)

            }
            .padding(.all, 10)
            .cornerRadius(8)
    }
}

struct ResultEntry: View {
    let contest : ContestForJudge
    var onNewResult : () -> Void
    @Binding var name: String
    @Binding var metric : Metric
    let isEdit: Bool;
    
    func enterUnitText(unit: String) -> String {
        switch unit.lowercased() {
            case "m": return "Länge in Metern";
            case "s": return "Zeit in Sekunden";
            case "kg": return "Gewicht in Kilogramm";
            default: return "Unknown unit";
        }
    }
    
    func getMetricFieldToEdit(metric: Binding<Metric>, unit: String) -> Binding<Float32> {
        switch unit.lowercased() {
            case "m": return metric.length;
            case "s": return metric.time;
            case "kg": return metric.weight;
            default: return metric.time;
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("Gebe Daten ein")
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 15)
            
            Text("Teilnehmer")

            TextField("Name des Teilnehmers", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 300)
            
                FloatInput(onNewResult: onNewResult,
                           entryTitle: enterUnitText(unit: contest.ct_unit),
                           name: $name,
                           value: getMetricFieldToEdit(metric: $metric, unit: contest.ct_unit),
                           startingInput: isEdit ? String(getMetricFieldToEdit(metric: $metric, unit: contest.ct_unit).wrappedValue) : "")

        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

struct FloatInput : View {
    var onNewResult: () -> Void
    let entryTitle : String
    @Binding var name: String
    @Binding var value: Float32
    let startingInput: String

    @State private var valueInput : String = ""
    @State private var isValid : Bool = false;

    var body: some View {
        Text(entryTitle)
        
        TextField("0.0", text: $valueInput)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .padding()
            .multilineTextAlignment(.center)
            .frame(width: 90)
            .foregroundColor(isValid ? .black : .red)
            .onAppear(){ valueInput = startingInput }
            .onChange(of: valueInput) {
                isValid = validateInput(input: valueInput);
                if(isValid) { value = Float(valueInput.replacingOccurrences(of: ",", with: ".")).unsafelyUnwrapped }
            }

        Button(action: {
            if(!name.isEmpty && validateInput(input: valueInput)) {
                onNewResult();
                valueInput.removeAll();
            }
        }) {
            
            Text("Bestätigen").foregroundColor((isValid && !name.isEmpty) ? Color.black : Color.gray)
        }
        .padding(.vertical, 10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .disabled(!isValid || name.isEmpty)
    }
    
    private func validateInput(input: String) -> Bool {
        let commaSwitchedToPoint = input.replacingOccurrences(of: ",", with: ".");
        return Float(commaSwitchedToPoint) != nil
    }
}



