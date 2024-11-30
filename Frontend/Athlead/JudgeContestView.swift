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

struct ResultInfo {
    let name: String
    let metric: Metric
}

struct JudgeContestView : View {
    let COMPETITION : String
    @State private var results: [ResultInfo] = [/*ResultInfo(name: "", metric: Metric())*/]
    // Variables for adding
    @State private var newParticipantName: String = ""
    @State private var newMetric: Metric = Metric()
    
    @State private var showConfirmationDialog = false // Show confirmation dialog for removing results
    @State private var resultToRemoveIndex: Int = 0 // The result to be removed (for confirmation)
    
    // Variables for editing
    @State private var showEditSheet: Bool = false
    @State private var nameToEdit: String = ""
    @State private var metricToEdit: Metric = Metric()
    @State private var editingIndex: Int? = nil // Index of the result being edited
    
    var body: some View {
        VStack {
            MetricEntry(
                COMPETITION: COMPETITION,
                onNewResult: {
                    results.append(ResultInfo(name:newParticipantName, metric:newMetric));
                    newParticipantName = ""
                    newMetric = Metric()
                },
                metric: $newMetric,
                name: $newParticipantName,
                isEdit: false)
            .padding()
            
            if(!results.isEmpty) {
                List {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        ForEach(results.indices, id: \.self) { index in
                            HStack {
                                if(COMPETITION == "100m Lauf") {
                                    Text("'\(results[index].name)' \(results[index].metric.time, specifier: "%.2f")\(results[index].metric.timeUnit)")
                                                                        .padding(.leading)
                                } else if(COMPETITION == "Weitsprung")
                                {
                                    Text("'\(results[index].name)' \(results[index].metric.length, specifier: "%.2f")\(results[index].metric.lengthUnit)")
                                                                        .padding(.leading)
                                } else if(COMPETITION == "Hochsprung")
                                {
                                    Text("'\(results[index].name)' \(results[index].metric.length, specifier: "%.2f")\(results[index].metric.lengthUnit)")
                                                                        .padding(.leading)
                                } else {
                                    Text("Competition unknown")
                                }
                                
                                
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
                } //List
                .padding(.top, 5)
                .foregroundColor(.primary)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                .background(Color.white)
                .scrollContentBackground(.hidden)
                .confirmationDialog(
                    "Are you sure you want to remove this result?",
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible) {
                        Button("Remove", role: .destructive) {
                            results.remove(at: $resultToRemoveIndex.wrappedValue)
                        }
                } // Dialog
            } else { // List is empty
                Text("Keine Einträge bisher")
                
            }
        }
                .sheet(isPresented: $showEditSheet) {
                    EditResultView(COMPETITION: COMPETITION,
                                   nameToEdit: $nameToEdit,
                                   metricToEdit: $metricToEdit,
                                   onSave: {
                        // Save the edited result back to the list
                        if let index = editingIndex {
                            results[index] = ResultInfo(name: nameToEdit, metric: metricToEdit)
                        }
                        // Close the sheet
                        showEditSheet = false
                    }, showEditSheet: $showEditSheet )
                }.frame(width: UIScreen.main.bounds.width * 0.7)
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
    var onSave: () -> Void
    @Binding var showEditSheet: Bool // Added this to control the sheet dismissal
    
    var body: some View {
            VStack {
                Text("Ändere den Eintrag").font(.title).bold().padding(.top, 10).padding(.bottom, 15)

                MetricEntry(COMPETITION:COMPETITION,
                            onNewResult : onSave,
                            metric : $metricToEdit,
                            name: $nameToEdit,
                            isEdit: true)
                
            }
            .padding(.all, 10)
            .cornerRadius(8)
    }
}

struct MetricEntry: View {
    let COMPETITION : String
    var onNewResult : () -> Void
    var metric: Binding<Metric>
    var name: Binding<String>
    let isEdit: Bool;

    var body: some View {
        VStack(spacing: 1) {
            Text("Gebe Daten ein")
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 15)
            
            Text("Teilnehmer")

            TextField("Name des Teilnehmers", text: name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 300)
            
            if(COMPETITION == "100m Lauf")
            {
                FloatInput(onNewResult: onNewResult,
                           entryTitle: "Zeit in Sekunden",
                           name: name,
                           txtBeforeValue: "ist 100m in",
                           value: metric.time,
                           txtAfterValue: "s gelaufen.",
                           startingInput: isEdit ? String(metric.time.wrappedValue) : "")
            } else if(COMPETITION == "Weitsprung")
            {
                FloatInput(onNewResult: onNewResult,
                           entryTitle: "Weite in Meter",
                           name: name,
                           txtBeforeValue: "ist",
                           value: metric.length,
                           txtAfterValue: "m weit gesprungen.",
                           startingInput: isEdit ? String(metric.length.wrappedValue) : "")
            } else if(COMPETITION == "Hochsprung")
            {
                FloatInput(onNewResult: onNewResult,
                           entryTitle: "Höhe in Meter",
                           name: name,
                           txtBeforeValue: "ist",
                           value: metric.length,
                           txtAfterValue: "m hoch gesprungen.",
                           startingInput: isEdit ? String(metric.length.wrappedValue) : "")
            } else {
                Text("Unknown competition")
            }

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
    var name: Binding<String>
    let txtBeforeValue: String
    var value: Binding<Float32>
    let txtAfterValue: String
    let startingInput: String;
    
    @State private var valueInput : String = ""
    @State private var isValid : Bool = false;
    
    var body: some View {
        Text(entryTitle)
        
        TextField("0,0", text: $valueInput)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .padding()
            .multilineTextAlignment(.center)
            .frame(width: 80)
            .foregroundColor(isValid ? .black : .red)
            .onAppear(){ valueInput = startingInput }
            .onChange(of: valueInput){
                isValid = validateInput(input: valueInput);
                if(isValid) { value.wrappedValue = Float(valueInput.replacingOccurrences(of: ",", with: ".")).unsafelyUnwrapped }
            }
            

        Text(name.wrappedValue.isEmpty ? " " :
                ( "\(name.wrappedValue.truncated(to: 12)) \(txtBeforeValue) \(value.wrappedValue, specifier: "%.2f") \(txtAfterValue)" ))
            .font(.subheadline)
            .padding(.all, 10)
            .bold()
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        Button(action: {
            if(!name.wrappedValue.isEmpty && validateInput(input: valueInput)) {
                onNewResult();
                valueInput.removeAll();
            }
        }) {
            
            Text("Bestätigen").foregroundColor(Color.black)
        }
        .padding(.vertical, 10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
    
    private func validateInput(input: String) -> Bool {
        let commaSwitchedToPoint = input.replacingOccurrences(of: ",", with: ".");
        return Float(commaSwitchedToPoint) != nil
    }
}



