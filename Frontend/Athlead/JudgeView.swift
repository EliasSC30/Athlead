//
//  JudgeView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 29.11.24.
//

import SwiftUI

struct JudgeView : View {
    @State private var results: [Metric] = [Metric()] // Store results as strings
    @State private var newMetric: Metric = Metric() // Input for new result
    @State private var showConfirmationDialog = false // Show confirmation dialog for removing results
    @State private var resultToRemoveIndex: Int = 0 // The result to be removed (for confirmation)
    
    @State private var showEditSheet: Bool = false
    @State private var metricToEdit: Metric = Metric()
    @State private var editingIndex: Int? = nil // Index of the result being edited
    
    var body: some View {
        VStack {
            HundredMeterEntry(time: $newMetric.time)
                .padding()
            
            // List of results with edit and delete options
            List {
                Section(header: Text("Eingetragene Ergebnisse").font(.headline)) {
                    ForEach(results.indices, id: \.self) { index in
                        HStack {
                            Text(results[index].time.formatted() + results[index].timeUnit)
                                .padding(.leading)
                            
                            Spacer()
                            
                            // Edit button
                            Button(action: {
                                // Logic to edit the result (for simplicity, just modify the result here)
                                self.editingIndex = index
                                self.metricToEdit = self.results[index]
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
            }
            .padding(.top, 5)
            .foregroundColor(.primary)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .background(Color.white)
            .scrollContentBackground(.hidden)
            .confirmationDialog(
                "Are you sure you want to remove this result?",
                isPresented: $showConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    results.remove(at: $resultToRemoveIndex.wrappedValue)
                }
            }
            Button("Cancel", role: .cancel) {
                
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditResultView(metricToEdit: $metricToEdit, onSave: {
                // Save the edited result back to the list
                if let index = editingIndex {
                    results[index] = metricToEdit
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
    @Binding var metricToEdit: Metric
    var onSave: () -> Void
    @Binding var showEditSheet: Bool // Added this to control the sheet dismissal
    
    var body: some View {
            VStack {
                Text("Edit Result").font(.title).bold().padding(.top, 10)

                HundredMeterEntry(time : $metricToEdit.time)
                
                HStack {
                    Button("Cancel") {
                        // Dismiss the sheet
                        self.showEditSheet = false
                    }
                    .padding(.all, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("Save") {
                        onSave() // Call the save action to save the edited result
                        //self.showEditSheet = false // Dismiss the sheet after saving
                    }
                    .padding(.all, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.all, 10)
            .cornerRadius(8)
    }
}

struct HundredMeterEntry: View {
    var time: Binding<Float>
    @State var name: String = ""

    var body: some View {
        VStack(spacing: 1) {
            Text("Enter a result for 100m") // Title for the input field
                .font(.title)
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 15)
            
            Text("Teilnehmer")
            TextField("Name des Teilnehmer", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(width: 150) // Limit the width of the text field
            
            Text("Zeit in Sekunden")
            // TextField for entering the float value
            TextField("0.00", value: time, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad) // Ensure the user can enter decimal numbers
                .padding()
                .frame(width: 100) // Limit the width of the text field

            Text("\"\(name)\" ran 100m in \(time.wrappedValue, specifier: "%.2f") seconds")
                .font(.subheadline)
                .padding(.all, 10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}


