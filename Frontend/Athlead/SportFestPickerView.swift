//
//  SportFestPickerView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 04.12.24.
//

import SwiftUI


struct SportFestPickerView: View {
    
    let apiURL = "http://localhost:8000"
    
    
    @Binding var selectedContest: CTemplate?
    @Binding var selectedLocation: Location?
    @State private var sportfests: [SportFestDisplay] = []
    @State private var selectedSportfest: SportFestDisplay?
    
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    @State private var showConfirmation = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Sportfests")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if sportfests.isEmpty {
                Text("No sportfests available.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            } else {
                List {
                    ForEach(sportfests) { sportfest in
                        VStack(alignment: .leading) {
                            Text(sportfest.NAME)
                                .font(.headline)
                            Text("\(formatDate(date: sportfest.START)) - \(formatDate(date: sportfest.END))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSportfest = sportfest
                            showConfirmation = true
                        }
                    }
                }
                .alert(isPresented: $showConfirmation) {
                    Alert(
                        title: Text("Confirm Action"),
                        message: Text("Are you sure you want to add the contest to **\(selectedSportfest?.NAME ?? "this sportfest")**? You will be inserted as the contact person, which you can always change later."),
                        primaryButton: .default(Text("Yes")) {
                            if let sportfest = selectedSportfest {
                                assignToSportfest(sportfest: sportfest)
                            }
                        },
                        secondaryButton: .cancel(Text("No"))
                    )
                }
            }
        }
        .navigationTitle("Select Sportfest")
        .navigationBarItems(trailing: Button(action: loadSportFests) {
            Image(systemName: "arrow.clockwise")
        })
        .onAppear(perform: loadSportFests)
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    
    
    func assignToSportfest(sportfest: SportFestDisplay) {
        let url = URL(string: "\(apiURL)/sportfests/\(sportfest.ID)/contests")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateOf1970 = Date(timeIntervalSince1970: 0)
        
        let contest = AssignContestSportFestCreate(LOCATION_ID: selectedLocation!.ID, CONTACTPERSON_ID: "4baffe97-d71f-4034-b254-2dc2e7f45be9", C_TEMPLATE_ID: selectedContest!.ID, NAME: selectedContest!.NAME, START: dateOf1970, END: dateOf1970)
        
        guard let encoded = try? JSONEncoder().encode(contest) else {
            print("Failed to encode contest")
            return
        }
        
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error assigning contest to sportfest: \(error)")
                return
            }
            print(response!)
            if let str = String(data: data!, encoding: .utf8) {
                print(str)
            }
        }.resume()
        
        print("Assigned to \(sportfest.NAME)")
    }
    
    private func loadSportFests(){
        print(selectedContest)
        print(selectedLocation)
        isLoading = true
        errorMessage = nil
        
        let url = URL(string: "\(apiURL)/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching sportfests: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch sportfests"
                }
                return
            }
            
            guard let data = data, let sportfestsResponse = try? JSONDecoder().decode(SportFestsResponse.self, from: data) else {
                print("Failed to decode sportfests")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch sportfests"
                }
                return
            }
            
            let sportfests = sportfestsResponse.data
            
            for sportfest in sportfests {
                let details_id = sportfest.details_id
                let detailUrl = URL(string: "\(apiURL)/details/\(details_id)")!
                var detailRequest = URLRequest(url: detailUrl)
                detailRequest.httpMethod = "GET"
                detailRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                URLSession.shared.dataTask(with: detailRequest) { data, response, error in
                    if let error = error {
                        print("Error fetching details: \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Failed to fetch sportfests"
                        }
                        return
                    }
                    guard let data = data, let detailsResponse = try? JSONDecoder().decode(DetailResponse.self, from: data) else {
                        print("Failed to decode details")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Failed to fetch sportfests"
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        let formatter = DateFormatter()
                        
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        formatter.timeZone = TimeZone(abbreviation: "UTC")
                        
                        let endDate = formatter.date(from: detailsResponse.data.END) ?? Date()
                        let startDate = formatter.date(from: detailsResponse.data.START) ?? Date()
                        
                        let sportfest = SportFestDisplay(ID: sportfest.id, DETAILS_ID: sportfest.details_id, CONTACTPERSON_ID: detailsResponse.data.CONTACTPERSON_ID, NAME: detailsResponse.data.NAME, LOCATION_ID: detailsResponse.data.LOCATION_ID, START: startDate, END: endDate)
                        
                        
                        if !self.sportfests.contains(sportfest) {
                            self.sportfests.append(sportfest)
                        }
                        isLoading = false
                        errorMessage = nil
                        
                        
                        
                    }
                }.resume()
                
            }
            
        }.resume()
        
        
    }
}
