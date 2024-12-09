//
//  AssignContestToSportfestView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 04.12.24.
//
import SwiftUI

struct AssignContestToSportfestView: View {
    
    @State private var contests: [CTemplate] = []
    @State private var selectedContest: CTemplate?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Contests")
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
                        NavigationLink(destination: LocationPickerView(selectedContest: $selectedContest)) {
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
                            }.onTapGesture {
                                selectedContest = contest
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Assign Contests")
        .onAppear(perform: fetchContests)
        .navigationBarItems(trailing: Button(action: fetchContests) {
            Image(systemName: "arrow.clockwise")
        })
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
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch contests: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data, let contestsResponse = try? JSONDecoder().decode(CTemplatesResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to decode contests."
                }
                return
            }
            
            DispatchQueue.main.async {
                self.contests = contestsResponse.data
                self.isLoading = false
            }
        }.resume()
    }
}
struct LocationPickerView: View {
    
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @Binding var selectedContest: CTemplate?
    @State private var locations: [Location] = []
    @State private var selectedLocation: Location?
    
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Locations")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if locations.isEmpty {
                Text("No locations available.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            } else {
                List {
                    ForEach(locations) { location in
                        NavigationLink(destination: SportFestPickerView(selectedContest: $selectedContest, selectedLocation: $selectedLocation)) {
                            VStack(alignment: .leading) {
                                Text(location.NAME)
                                    .font(.headline)
                                Text("\(location.STREET) \(location.STREETNUMBER), \(location.ZIPCODE) \(location.CITY)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }.onTapGesture {
                                selectedLocation = location
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Location")
        .navigationBarItems(trailing: Button(action: loadLocations) {
            Image(systemName: "arrow.clockwise")
        })
        .onAppear(perform: loadLocations)
    }
    
    private func loadLocations() {
        isLoading = true
        errorMessage = nil
        
        let url = URL(string: "\(apiURL)/locations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch locations"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch locations"
                }
                return
            }
            
            do {
                let locationresponse = try JSONDecoder().decode(
                    LocationsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.locations = locationresponse.data
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                print("Error decoding locations: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch locations"
                }
            }
            
        }.resume()
    }
    
}
