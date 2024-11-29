//
//  JudgeView.swift
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

struct JudgeView : View {
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
            HundredMeterEntry(onNewResult: {
                results.append(ResultInfo(name:newParticipantName, metric:newMetric));
                newParticipantName = ""
                newMetric = Metric()
            },
                              time: $newMetric.time, name: $newParticipantName)
            .padding()
            
            if(!results.isEmpty) {
                List {
                    Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                        ForEach(results.indices, id: \.self) { index in
                            HStack {
                                Text("'\(results[index].name)' \(results[index].metric.time, specifier: "%.2f")\(results[index].metric.timeUnit)")
                                    .padding(.leading)
                                
                                Spacer()
                                
                                // Edit button
                                Button(action: {
                                    // Logic to edit the result (for simplicity, just modify the result here)
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
                    EditResultView(nameToEdit: $nameToEdit,
                                   metricToEdit: $metricToEdit,
                                   onSave: {
                        // Save the edited result back to the list
                        if let index = editingIndex {
                            results[index] = ResultInfo(name: newParticipantName, metric: metricToEdit)
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
    @Binding var nameToEdit : String
    @Binding var metricToEdit: Metric
    var onSave: () -> Void
    @Binding var showEditSheet: Bool // Added this to control the sheet dismissal
    
    var body: some View {
            VStack {
                Text("Ändere Eintrag").font(.title).bold().padding(.top, 10)

                HundredMeterEntry(onNewResult : onSave, time : $metricToEdit.time, name: $nameToEdit)
                
            }
            .padding(.all, 10)
            .cornerRadius(8)
    }
}

struct HundredMeterEntry: View {
    var onNewResult : () -> Void
    var time: Binding<Float>
    @Binding var name: String

    var body: some View {
        VStack(spacing: 1) {
            Text("Gebe Daten ein") // Title for the input field
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 15)
            
            Text("Teilnehmer")
            TextField("Name des Teilnehmers", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 300) // Limit the width of the text field
            
            Text("Zeit in Sekunden")
            // TextField for entering the float value
            TextField("0.00", value: time, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad) // Ensure the user can enter decimal numbers
                .padding()
                .multilineTextAlignment(.center)
                .frame(width: 80) // Limit the width of the text field

            Text(name.isEmpty ? " " : ( "\(name.truncated(to: 12)) ran 100m in \(time.wrappedValue, specifier: "%.2f") seconds" ))
                .font(.subheadline)
                .padding(.all, 10)
                .bold()
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            Button(action: {
                if(!name.isEmpty && time.wrappedValue != 0.0) {
                    onNewResult();
                }
            }) {
                
                Text("Bestätigen").foregroundColor(Color.black)
            }
            .padding(.vertical, 10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}


