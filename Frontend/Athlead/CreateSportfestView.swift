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
                                
                            }
                            
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
            
            guard let data = data else {
                return
            }
            
            do {
                let personResponse = try JSONDecoder().decode(PersonsResponse.self, from: data)
                let persons = personResponse.data
                
                let dispatchGroup = DispatchGroup()
                
                var contacts: [Person] = []
                let contactLock = NSLock()
                
                for person in persons {
                    
                    guard person.ROLE.lowercased() == "admin" else {
                        continue
                    }
                    
                    dispatchGroup.enter()
                    
                    contactLock.lock()
                    contacts.append(person)
                    contactLock.unlock()
                }
                
                dispatchGroup.notify(queue: DispatchQueue.main) {
                    self.contactPersons = contacts
                    self.selectedContact = contacts.first
                    self.isLoading[1] = false
                    self.errorMessageLoad = nil
                }
                
            } catch {
                print("Error decoding persons: \(error)")
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
        
        let details = SportfestDetailsCreate(
            NAME: sportfestName,
            LOCATION_ID: selectedLocation.ID,
            CONTACTPERSON_ID: selectedContact.ID,
            START: String(startDate.ISO8601Format().dropLast()),
            END: String(endDate.ISO8601Format().dropLast())
        )
        
        
        let detailsURL = URL(string: "\(apiURL)/details")!
        
        var detailsRequest = URLRequest(url: detailsURL)
        detailsRequest.httpMethod = "POST"
        detailsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            detailsRequest.httpBody = try JSONEncoder().encode(details)
        } catch (let e){
            print("Error encoding details: \(e)")
        }
        
        
        let str = String(data: detailsRequest.httpBody!, encoding: .utf8)
        print("Details Request: \(str!)")
        
        
        URLSession.shared.dataTask(with: detailsRequest) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error creating details: \(error.localizedDescription)"
                    self.isSubmitting = false
                }
                return
            }
        
            guard let data = data, let detailsResponse = try? JSONDecoder().decode(SportfestDetailsResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create details. Please try again."
                    self.isSubmitting = false
                }
                return
            }
            
            let detailsID = detailsResponse.result.ID
            
            
            let sportfest = SportFestCreate(DETAILS_ID: detailsID)
            let sportfestURL = URL(string: "\(apiURL)/sportfests")!
            
            var sportfestRequest = URLRequest(url: sportfestURL)
            sportfestRequest.httpMethod = "POST"
            sportfestRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            sportfestRequest.httpBody = try? JSONEncoder().encode(sportfest)
            
            URLSession.shared.dataTask(with: sportfestRequest) { data, response, error in
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error creating sportfest: \(error.localizedDescription)"
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    guard let data = data, let sportfestResponse = try? JSONDecoder().decode(SportFestResponse.self, from: data) else {
                        self.errorMessage = "Failed to create sportfest. Please try again."
                        return
                    }
                    self.newSportfestID = sportfestResponse.data.id
                    self.errorMessage = nil
                    self.isSuccesful = true
                }
            }.resume()
            
        }.resume()
    }
    
}

// Preview
struct CreateSportfestView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSportfestView()
    }
}
