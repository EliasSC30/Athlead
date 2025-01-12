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
                                Task {
                                    await createSportfest()
                                }
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
        Task {
            await fetchLocations()
            await fetchContacts()
        }
    }
    
    private func fetchLocations() async {
        isLoading[0] = true
        errorMessageLoad = nil
        
        
        let url = URL(string: "\(apiURL)/locations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                let locationData = try JSONDecoder().decode(LocationsResponse.self, from: data)
                locations = locationData.data
                selectedLocation = locations.first
                isLoading[0] = false
                errorMessageLoad = nil
            default:
                break
            }
        } catch {
            errorMessageLoad = "Error fetching locations"
            print("Error fetching locations: \(error)")
        }
    }
    
    private func fetchContacts() async {
        isLoading[1] = true
        errorMessageLoad = nil
        
        let personsURL = URL(string: "\(apiURL)/persons")!
        var request = URLRequest(url: personsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                let personsData = try JSONDecoder().decode(PersonsResponse.self, from: data)
                let persons = personsData.data.filter { $0.ROLE.uppercased() == "ADMIN" }
                
                contactPersons = persons
                selectedContact = contactPersons.first
                isLoading[1] = false
                errorMessageLoad = nil
            default:
                break
            }
        } catch {
            errorMessageLoad = "Error fetching contactpersons"
            print("Error fetching locations: \(error)")
        }
    }
    
    private func createSportfest() async {
        guard let selectedLocation = selectedLocation,
              let selectedContact = selectedContact else {
            self.errorMessage = "Please select a location and a contact person."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let url = URL(string: apiURL + "/sportfests_with_location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sportfest: SportfestLocationCreate = SportfestLocationCreate(location_id: selectedLocation.ID, CONTACTPERSON_ID: selectedContact.ID, fest_name: sportfestName, fest_start: String(startDate.ISO8601Format().dropLast()), fest_end: String(endDate.ISO8601Format().dropLast()))
        
        guard let body = try? JSONEncoder().encode(sportfest) else {
            errorMessage = "Could not encode sportfest."
            isSuccesful = false
            isSubmitting = false
            return
        }
        request.httpBody = body
        
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                isSubmitting = false
                guard let sportFestResponse = try? JSONDecoder().decode(SportfestLocationCreateResponse.self, from: data) else {
                    isSuccesful = false
                    errorMessage = "Could not decode sportfest."
                    return
                }
                if sportFestResponse.status == "success" {
                    // Invalidate cache after successful creation of the sportfest
                    invalidateSportfestCache()
                }
                isSuccesful = sportFestResponse.status == "success"
                errorMessage = sportFestResponse.status == "success" ? nil : "Could not create sportfest."
                newSportfestID = sportFestResponse.status == "success" ? "dummy" : sportFestResponse.data.ID
            default:
                break
            }
        } catch {
            isSubmitting = false
            isSuccesful = false
            errorMessage = "Could not create sportfest."
            print("Error creating sportfest: \(error)")
        }
    }

    private func invalidateSportfestCache() {
        // Invalidate the cache by removing it from UserDefaults
        UserDefaults.standard.removeObject(forKey: "cachedSportfests")
        UserDefaults.standard.removeObject(forKey: "cacheExpiry")
    }

    
}

// Preview
struct CreateSportfestView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSportfestView()
    }
}
