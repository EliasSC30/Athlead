//
//  AddContestView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 04.12.24.
//
import SwiftUI

struct AddContestView: View {
    
    struct DummyContestant: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let result: Int
        let unit: String
    }

    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var gradeStart: Int = 1
    @State private var gradeEnd: Int = 4
    @State private var evaluationOrder: [DummyContestant] = [
        DummyContestant(name: "Jan", result: Int.random(in: 1...1000), unit: "s"),
        DummyContestant(name: "Elias", result: Int.random(in: 1...1000), unit: "s")
    ]
    @State private var unit: String = ""
    @State private var showAlert: Bool = false
    @State private var created: Bool = false
    @State private var dragAndDropAsc: Bool = true

    var grades: [Int] = Array(1...4)

    var body: some View {
            Form {
                Section(header: Text("Contest Information")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    TextField("Description (Optional)", text: $description)
                        .autocapitalization(.sentences)
                        .textInputAutocapitalization(.sentences)

                    HStack {
                        Picker("Grade", selection: $gradeStart) {
                            ForEach(grades, id: \.self) { grade in
                                Text("\(grade)").tag(grade)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        
                        Text("to")

                        Picker("Grade", selection: $gradeEnd) {
                            ForEach(grades, id: \.self) { grade in
                                Text("\(grade)").tag(grade)
                            }
                        }
                        
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    
                    TextField("Unit", text: $unit)
                        .autocapitalization(.words)
                        .textInputAutocapitalization(.words)
                        .onChange(of: unit) { _ in
                            evaluationOrder = evaluationOrder.map { DummyContestant(name: $0.name, result: Int.random(in: 1...1000), unit: self.unit) }
                        }
                    
                }

                Section(header: Text("Evaluation")) {
                    List {
                        ForEach(evaluationOrder) { DummyContestant in
                            HStack {
                                Text(DummyContestant.name)
                                Spacer()
                                Text("\(DummyContestant.result) \(DummyContestant.unit)")
                            }
                            .padding(.vertical, 5)
                        }
                        .onMove { indices, newOffset in
                            evaluationOrder.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                    .environment(\.editMode, .constant(.active))
                }
                //Text erklärung drag and drop
                Text("In order to analyse the ranking of the contestants, you can drag and drop the contestants in the order of their results. The first contestant in the list will be the winner. The order will be saved as the evaluation order, for the contest and all results within.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                

                Button(action: {
                    if name.isEmpty || unit.isEmpty {
                        showAlert = true
                    } else {
                        submitContest()
                    }
                }) {
                    Text("Add Contest")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Missing Required Fields"),
                        message: Text("Please fill in the Name and Unit fields."),
                        dismissButton: .default(Text("OK"))
                    )
                }.popover(isPresented: $created) {
                    Text("Contest created successfully")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .font(.headline)
                    
                }
            }
            .navigationTitle("Add Contest")
            .navigationBarTitleDisplayMode(.inline)
        
    }

    private func validateGradeRange() {
        if gradeStart > gradeEnd {
            // If start is greater than end, adjust end to match start
            gradeEnd = gradeStart
        }
    }

    private func submitContest() {
        
        let ascending = evaluationOrder[0].result < evaluationOrder[1].result
        let url = URL(string: "\(apiURL)/ctemplates")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let ctemplate = CreateCTemplate(NAME: name, DESCRIPTION: description,
                                        GRADERANGE: "\(gradeStart)-\(gradeEnd)",
                                        EVALUATION: ascending ? "ASCENDING" : "DESCENDING",
                                        UNIT: unit)
        guard let encoded = try? JSONEncoder().encode(ctemplate) else {
            print("Failed to encode contest template")
            return
        }
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting contest: \(error)")
                return
            }
            
            
            
            guard let data = data, let response = try? JSONDecoder().decode(CreateCTemplateResponse.self, from: data) else {
                    print("Failed to decode contest response")
                return
            }
            
            DispatchQueue.main.async {
                self.created = true
            }
            
        }.resume();
    }
}

struct AddContestView_Previews: PreviewProvider {
    static var previews: some View {
        AddContestView()
    }
}
