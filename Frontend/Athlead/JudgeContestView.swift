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
            fetch("\(apiURL)/contests/\(contest.ct_id)/participants", ParticipantsForJudge.self){ result in
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
                List {
                    ForEach(participants){ participant in
                        HStack {
                            Text("\(participant.f_name) \(participant.l_name)")
                            Spacer()
                            if (participant.pics == 1){
                                Image(systemName: "camera")
                            } else {
                                Image(systemName: "camera")
                                    .symbolVariant(.slash)
                                    .foregroundColor(Color.red)
                                    .opacity(0.5)
                            }
                        }
                        .padding()
                        .background(Color.white)
                    }
                }
            }
        }
    }
}

struct JudgeEntryView : View {
    @State var contest : ContestForJudge
    
    @State private var contestResults: [ContestResult] = [];
    
    // Variables for editing
    @State private var startingInput: String = "";
    @State private var editingIndex: Int = 0;
    
    private func formattedString(ctr: ContestResult) -> String {
        var ret = ctr.p_firstname + " " + ctr.p_lastname + " ";
        if (ctr.value == nil) {
            ret += "-";
        } else {
            ret += floatToString(ctr.value!)+contest.ct_unit.lowercased();
        }
        return ret;
    }
    
    var body: some View {
        VStack {
            if(!contestResults.isEmpty) {
                ResultEntry(
                    contest: contest,
                    startingInput: $startingInput,
                    nameOfParticipant: (contestResults[editingIndex].p_firstname+" "+contestResults[editingIndex].p_lastname),
                    onNewResult: { (value: Float64) -> Void in contestResults[editingIndex].value = value; }
                    )
                .padding()
                
                List {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        ForEach(contestResults.indices, id: \.self) { index in
                            HStack {
                                Text(formattedString(ctr: contestResults[index])).padding(.leading)
                                Spacer()

                                // Edit button
                                Button(action: {
                                    self.editingIndex = index;
                                    startingInput = (contestResults[editingIndex].value == nil) ? "" : String(format:"%.2f",contestResults[editingIndex].value.unsafelyUnwrapped);
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
        }.onAppear {
            fetch("\(apiURL)/contests/\(contest.ct_id)/contestresults", ContestResultsResponse.self){
                response in
                switch response {
                case .success(let resp): contestResults = resp.data;
                case .failure(let err): print(err);
                }
            }
        }.onDisappear {
            var patch = PatchContestResults(results: []);
            for contestResult in contestResults {
                print(contestResult)
                if contestResult.value != nil {
                    patch.results.append(PatchContestResult(p_id: contestResult.p_id, value: contestResult.value.unsafelyUnwrapped))
                }
            }
            fetch("\(apiURL)/contests/\(contest.ct_id)/contestresults", PatchContestResultsResponse.self, "PATCH", nil, patch){
                response in
                switch response {
                case .success(let resp): print(resp)
                case .failure(let err): print(err)
                }
            }
        }
    }
    
    private func floatToString(_ val: Float64) -> String { return String(format: "%.2f", val) }

    // Handle deletion via swipe-to-delete
    private func delete(at offsets: IndexSet) {
        contestResults.remove(atOffsets: offsets)
    }
}

struct ResultEntry: View {
    let contest : ContestForJudge
    @Binding var startingInput: String
    let nameOfParticipant: String
    var onNewResult : (Float64) -> Void
    
    func enterUnitText(_ unit: String) -> String {
        switch unit.lowercased() {
            case "m": return "Länge in Metern";
            case "s": return "Zeit in Sekunden";
            case "kg": return "Gewicht in Kilogramm";
            default: return "Unknown unit";
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("Gebe Daten ein")
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 15)

            Text(nameOfParticipant).padding()
            
            FloatInput(onNewResult: onNewResult,
                       entryTitle: enterUnitText(contest.ct_unit),
                       startingInput: $startingInput)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

struct FloatInput : View {
    @State var onNewResult: (Float64) -> Void;
    let entryTitle : String
    @State var value: Float64? = nil;
    @Binding var startingInput: String

    @State private var valueInput : String = ""
    @State private var isValid : Bool = false;

    var body: some View {
        VStack {
            Text(entryTitle)
            
            TextField("", text: $valueInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .foregroundColor(isValid ? .black : .red)
                .onAppear(){ valueInput = startingInput; }
                .onChange(of: startingInput){ valueInput = startingInput; }
                .onChange(of: valueInput) {
                    isValid = validateInput(input: valueInput);
                    if(isValid) { self.value = Float64(valueInput.replacingOccurrences(of: ",", with: ".")).unsafelyUnwrapped }
                }
            
            Button(action: {
                if(validateInput(input: valueInput)) {
                    valueInput.removeAll();
                    onNewResult(value.unsafelyUnwrapped);
                }
            }) {
                Text("Bestätigen").foregroundColor((isValid) ? Color.black : Color.gray)
            }
            .padding(.vertical, 10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .disabled(!isValid || value == nil)
        }
    }
    
    private func validateInput(input: String) -> Bool {
        let commaSwitchedToPoint = input.replacingOccurrences(of: ",", with: ".");
        return Float(commaSwitchedToPoint) != nil
    }
}



