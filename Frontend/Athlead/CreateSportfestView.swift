//
//  CreateSportfestView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//


import SwiftUI

struct CreateSportfestView: View {
    // Form State
    @State private var sportfestName: String = ""
    @State private var selectedLocation: Location? = nil
    @State private var selectedContact: Person? = nil
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var locations: [Location] = []
    @State private var contactPersons: [Person] = []
    
    @State private var isSubmitting: Bool = false
    @State private var isSuccesful: Bool = false
    @State private var errorMessage: String? = nil
    @State private var newSportfestID: String? = nil
    
    private let truncateLimit: Int = 21;
    
    @State private var isLoading: [Bool] = [true, true]
    @State private var errorMessageLoad: String?
    
    var body: some View {
        Group {
            if isLoading[0] && isLoading[1] {
                ProgressView("Loading Sportfest data...")
            } else if let error = errorMessageLoad {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                Form {
                    // Sportfest Name
                    Section(header: Text("Sportfest Details")) {
                        TextField("Sportfest Name", text: $sportfestName)
                            .autocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .background(Color.white.opacity(0.1))
                            
                            
                    }
                    
                    // Location Picker
                    Section(header: Text("Location")) {
                        Picker("Select Location", selection: $selectedLocation) {
                            ForEach(locations, id: \.self) { location in
                                Text("\(location.NAME) - \(location.CITY)".truncated(to: truncateLimit)).tag(location as Location)
                            }
                        }
                    }
                    
                    // Contact Person Picker
                    Section(header: Text("Contact Person")) {
                        Picker("Select Contact", selection: $selectedContact) {
                            ForEach(contactPersons) { contact in
                                Text("\(contact.FIRSTNAME) \(contact.LASTNAME)".truncated(to: truncateLimit)).tag(contact as Person)
                            }
                        }
                    }
                    
                    // Date Range
                    Section(header: Text("Event Dates")) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    // Submit Button
                    Section {
                        if isSubmitting {
                            ProgressView("Submitting...")
                        } else {
                            Button("Create Sportfest") {
                                createSportfest()
                            }.popover(isPresented: $isSuccesful) {
                                NavigationLink(destination: SportfestDetailView(sportfestID: newSportfestID!)) {
                                    Text("Sportfest created successfully. Click here to view.")
                                        .foregroundColor(.black)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                            }.disabled($sportfestName.wrappedValue.isEmpty || selectedLocation == nil || selectedContact == nil)
                            
                        }
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Create Sportfest")
            }
        }.onAppear(perform: fetchData)
    }
    
    private func fetchData() {
        fetchLocations()
        fetchContacts()
    }
    
    private func fetchLocations() {
        isLoading[0] = true
        errorMessageLoad = nil
        
        
        let url = URL(string: "\(apiURL)/locations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error)")
                DispatchQueue.main.async {
                    self.isLoading[0] = false
                    self.errorMessageLoad = "Error fetching locations"
                }
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let locationresponse = try JSONDecoder().decode(LocationsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.locations = locationresponse.data
                    self.selectedLocation = self.locations.first
                    self.isLoading[0] = false
                    self.errorMessageLoad = nil
                    
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading[0] = false
                    self.errorMessageLoad = "Error fetching locations"
                }
            }
            
        }.resume()
    }
    
    private func fetchContacts() {
        isLoading[1] = true
        errorMessageLoad = nil
        
        let personsURL = URL(string: "\(apiURL)/persons")!
        var request = URLRequest(url: personsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching persons: \(error)")
                DispatchQueue.main.async {
                    self.isLoading[1] = false
                    self.errorMessageLoad = "Error fetching administrators"
                }
                return
            }
            
            guard let data = data, let personsResponse = try? JSONDecoder().decode(PersonsResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.isLoading[1] = false
                    self.errorMessageLoad = "Failed to fetch administrators"
                }
                return
            }
            
            let persons = personsResponse.data.filter { $0.ROLE == "ADMIN" }
            
            DispatchQueue.main.async {
                self.contactPersons = persons
                self.selectedContact = self.contactPersons.first
                self.isLoading[1] = false
                self.errorMessageLoad = nil
            }
            
            
        }.resume()
    }
    
    private func createSportfest() {
        guard let selectedLocation = selectedLocation,
              let selectedContact = selectedContact else {
            self.errorMessage = "Please select a location and a contact person."
            return
        }
        isSubmitting = true
        errorMessage = nil
        
        
        let url = URL(string: apiURL + "/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let details = SportfestLocationCreate(CONTACTPERSON_ID: selectedContact.ID, fest_name: sportfestName, fest_start: String(startDate.ISO8601Format().dropLast()), fest_end:   String(endDate.ISO8601Format().dropLast()), city: selectedLocation.CITY, zip_code: selectedLocation.ZIPCODE, street: selectedLocation.STREET, streetnumber: selectedLocation.STREETNUMBER, location_name: selectedLocation.NAME)
        
        guard let encode = try? JSONEncoder().encode(details) else {
            print("Failed to encode details")
            errorMessage = "Failed to encode details"
            isSubmitting = false
            return
        }
        
        request.httpBody = encode
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error {
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error)"
                    self.isSubmitting = false
                }
                return
            }
            
            guard let data = data, let sportfestResponse = try? JSONDecoder().decode(SportfestCreateResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create sportfest. Please try again."
                    self.isSubmitting = false
                }
                
                return
            }
            
            DispatchQueue.main.async {
                
                self.newSportfestID = sportfestResponse.data.id
                self.errorMessage = nil
                self.isSuccesful = true
            }
        }.resume()
    }
    
}

// Preview
struct CreateSportfestView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSportfestView()
    }
}
