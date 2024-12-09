//
//  ManageContestView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 04.12.24.
//


import SwiftUI

struct ManageContestView: View {
    
    
    @State private var contests: [CTemplate] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
            Group {
                if isLoading {
                    ProgressView("Loading Contests...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else if contests.isEmpty {
                    Text("No contests available.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(contests) { contest in
                            NavigationLink(destination: AdminContestDetailView(contest: $contests[contests.firstIndex(where: { $0.id == contest.id })!])) {
                                VStack(alignment: .leading) {
                                    Text(contest.NAME)
                                        .font(.headline)
                                    if let description = contest.DESCRIPTION {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    if let gradeRange = contest.GRADERANGE {
                                        Text("Grades: \(gradeRange)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteContest)
                    }
                }
            }
            .navigationTitle("Manage Contests")
            .navigationBarItems(trailing: Button(action: fetchContests) {
                Image(systemName: "arrow.clockwise")
            })
            .onAppear(perform: fetchContests)
        
    }
    
    private func fetchContests() {
        isLoading = true
        errorMessage = nil
        
        
        let url = URL(string: apiURL + "/ctemplates")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error fetching contests: \(error)")
                return
            }
            
            guard let data = data, let contestsResponse = try? JSONDecoder().decode(CTemplatesResponse.self, from: data) else {
                print("Failed to decode contests")
                return
            }
            
            DispatchQueue.main.async {
                self.contests = contestsResponse.data
                self.isLoading = false
            }
                
            
        }.resume()
    
    }
    
    /// Handle deletion of contests
    private func deleteContest(at offsets: IndexSet) {
        contests.remove(atOffsets: offsets)
    }
}

struct AdminContestDetailView: View {
    
    @Binding var contest: CTemplate
    @State private var isEditing: Bool = false
    
    // Temporary storage for editing
    @State private var tempName: String = ""
    @State private var tempDescription: String = ""
    @State private var tempGradeRange: String = ""
    @State private var tempEvaluation: String = ""
    @State private var tempUnit: String = ""

    var body: some View {
        Form {
            if isEditing {
                Section(header: Text("Edit Contest Information")) {
                    TextField("Name", text: $tempName)
                    TextField("Description", text: $tempDescription)
                    TextField("Grade Range", text: $tempGradeRange)
                }

                Section(header: Text("Edit Evaluation")) {
                    TextField("Evaluation", text: $tempEvaluation)
                    TextField("Unit", text: $tempUnit)
                }
            } else {
                Section(header: Text("Contest Information")) {
                    Text("Name: \(contest.NAME)")
                    if let description = contest.DESCRIPTION {
                        Text("Description: \(description)")
                    }
                    if let gradeRange = contest.GRADERANGE {
                        Text("Grade Range: \(gradeRange)")
                    }
                }

                Section(header: Text("Evaluation")) {
                    Text("Evaluation Method: \(contest.EVALUATION)")
                    Text("Unit: \(contest.UNIT)")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Contest" : contest.NAME)
        .navigationBarItems(
            trailing: Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    saveChanges()
                } else {
                    startEditing()
                }
            }
        )
    }
    
    private func startEditing() {
        tempName = contest.NAME
        tempDescription = contest.DESCRIPTION ?? ""
        tempGradeRange = contest.GRADERANGE ?? ""
        tempEvaluation = contest.EVALUATION
        tempUnit = contest.UNIT
        isEditing = true
    }

    private func saveChanges() {
        contest = CTemplate(
            ID: contest.ID,
            NAME: tempName,
            DESCRIPTION: tempDescription.isEmpty ? nil : tempDescription,
            GRADERANGE: tempGradeRange.isEmpty ? nil : tempGradeRange,
            EVALUATION: tempEvaluation,
            UNIT: tempUnit
        )
        
        let updateContest = CreateCTemplate(
            NAME: tempName,
            DESCRIPTION: tempDescription.isEmpty ? nil : tempDescription,
            GRADERANGE: tempGradeRange.isEmpty ? nil : tempGradeRange,
            EVALUATION: tempEvaluation,
            UNIT: tempUnit
            )
        
        let url = URL(string: "\(apiURL)/ctemplates/\(contest.ID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        guard let encode = try? JSONEncoder().encode(updateContest) else {
            print("Failed to encode contest")
            return;
        }
        
        request.httpBody = encode
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating contest: \(error)")
                return
            }
            
            guard let data = data, let contestResponse = try? JSONDecoder().decode(UpdateCTemplateResponse.self, from: data) else {
                print("Failed to decode contest")
                return
            }
            
            
            DispatchQueue.main.async {
                self.isEditing = false
            }
            
            
        }.resume()
        
    
    }
}
