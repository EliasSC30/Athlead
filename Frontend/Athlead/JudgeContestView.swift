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
    let competitions: [ContestForJudge]
    
    var body: some View {
        NavigationStack {
            VStack {
                if competitions.isEmpty {
                    Text("You have no competitions")
                        .padding()
                        .background(Color.white)
                        .shadow(radius: 5.0)
                } else {
                    ForEach(competitions.indices, id: \.self) { index in
                        NavigationLink(destination: JudgeContestView(COMPETITION: competitions[index])) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(competitions[index].ct_name)
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
    let COMPETITION: ContestForJudge
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: JudgeEntryView(COMPETITION: COMPETITION)){
                    Text("Enter results")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
                
                NavigationLink(destination: JudgeScanView()){
                    Text("Register Contestants")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
            }
            
        }
    }
}

struct JudgeEntryView : View {
    let COMPETITION : ContestForJudge
    // Local results that update the results in the store when leaving
    @State private var results: [ResultInfo] = []

    // Variables for adding
    @State private var newParticipantName: String = ""
    @State private var newMetric: Metric = Metric()
    
    // Variables for editing
    @State private var showEditSheet: Bool = false
    @State private var nameToEdit: String = ""
    @State private var metricToEdit: Metric = Metric()
    @State private var editingIndex: Int = 0
    
    var body: some View {
        VStack {
            ResultEntry(
                COMPETITION: COMPETITION.ct_name,
                onNewResult: {
                    results.append(ResultInfo(name:newParticipantName, metric:newMetric));
                    newParticipantName = ""
                    newMetric = Metric()
                },
                name: $newParticipantName,
                metric: $newMetric,
                isEdit: false)
            .padding()
            
            if(!results.isEmpty) {
                List {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        ForEach(results.indices, id: \.self) { index in
                            HStack {
                                    Text("\(results[index].name) \(results[index].metric.time, specifier: "%.2f")\(results[index].metric.timeUnit)")
                                                                        .padding(.leading)
                                Spacer()

                                // Edit button
                                Button(action: {
                                    self.editingIndex = index
                                    self.metricToEdit = self.results[index].metric
                                    self.nameToEdit = self.results[index].name
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
            STORE[COMPETITION.ct_name] = results
        }
        .onAppear(){
            if(STORE[COMPETITION.ct_name]) != nil {
                results = STORE[COMPETITION.ct_name]!
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditResultView(COMPETITION: COMPETITION.ct_name,
                           nameToEdit: $nameToEdit,
                           metricToEdit: $metricToEdit,
                           onNewResult: {
                                // Save the edited result back to the list
                                if !results.isEmpty {
                                    results[editingIndex] = ResultInfo(name: nameToEdit, metric: metricToEdit)
                                }

                                showEditSheet = false
                            })
        }
        .padding(.top, 10)
    }
        

    // Handle deletion via swipe-to-delete
    private func delete(at offsets: IndexSet) {
        results.remove(atOffsets: offsets)
    }
}

struct EditResultView: View {
    let COMPETITION: String
    @Binding var nameToEdit : String
    @Binding var metricToEdit: Metric
    var onNewResult: () -> Void
    
    var body: some View {
            VStack {
                Text("Ändere den Eintrag").font(.title).bold().padding(.top, 10).padding(.bottom, 15)

                ResultEntry(COMPETITION:COMPETITION,
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
    let COMPETITION : String
    var onNewResult : () -> Void
    @Binding var name: String
    @Binding var metric : Metric
    let isEdit: Bool;

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
                           entryTitle: "Zeit in Sekunden",
                           name: $name,
                           value: $metric.time,
                           startingInput: isEdit ? String(metric.time) : "")

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



