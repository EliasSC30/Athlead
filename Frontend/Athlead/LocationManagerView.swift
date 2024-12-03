//
//  LocationManagerView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct LocationManagerView: View {

    let apiURL = "http://localhost:8000"

    @State private var allLocations: [Location] = []
    @State private var showAddLocation = false

    @State private var name = ""
    @State private var street = ""
    @State private var streetNumber = ""
    @State private var zipcode = ""
    @State private var city = ""

    var body: some View {
        VStack {
            List {
                Section(header: Text("Locations")) {
                    if allLocations.isEmpty {
                        Text("No locations available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(allLocations, id: \.self) { location in
                            NavigationLink(
                                destination: LocationView(location: location)
                            ) {
                                Label(
                                    location.NAME,
                                    systemImage: "mappin.and.ellipse")
                            }
                        }.onDelete(perform: {
                            indexSet in
                            let index = indexSet.first!
                            let location = allLocations[index]
                            deleteLocation(location: location)
                        })
                    }

                }.onAppear(perform: loadLocations)

                Section(header: Text("Add Location")) {
                    Button(action: {
                        showAddLocation = true
                    }) {
                        Label("Add Location", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .popover(
                        isPresented: $showAddLocation,
                        content: {
                            NavigationView {
                                Form {
                                    Section(
                                        header: Text("Location Details").font(
                                            .subheadline
                                        ).foregroundColor(.secondary)
                                    ) {
                                        HStack {
                                            Text("Name")
                                                .foregroundColor(.secondary)
                                                .padding(.trailing)
                                            Spacer()
                                            TextField("Name", text: $name)
                                                .textFieldStyle(
                                                    DefaultTextFieldStyle())
                                        }
                                    }

                                    Section(
                                        header: Text("Address").font(
                                            .subheadline
                                        ).foregroundColor(.secondary)
                                    ) {
                                        TextField("Street", text: $street)
                                            .textFieldStyle(
                                                DefaultTextFieldStyle())

                                        TextField(
                                            "Street Number", text: $streetNumber
                                        )
                                        .textFieldStyle(DefaultTextFieldStyle())
                                        .keyboardType(.numberPad)

                                        TextField("Zipcode", text: $zipcode)
                                            .textFieldStyle(
                                                DefaultTextFieldStyle())

                                        TextField("City", text: $city)
                                            .textFieldStyle(
                                                DefaultTextFieldStyle())
                                    }

                                    Button(action: createLocation) {
                                        HStack {
                                            Spacer()
                                            Text("Save")
                                                .font(.headline)
                                                .foregroundColor(
                                                    Color.accentColor)
                                            Spacer()
                                        }
                                    }

                                }
                                .navigationTitle("Create Location")
                                .navigationBarTitleDisplayMode(.inline)
                            }
                        })
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Locations")
        }
    }

    
    private func deleteLocation(location: Location){
        print("Deleting location \(location)")
        let url = URL(string: "\(apiURL)/locations/\(location.ID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting location: \(error)")
                return
            }
            
            if let str = String(data: data!, encoding: .utf8) {
                print("Response: \(str)")
            }
            
            
        }.resume()
        
    }
    
    private func createLocation() {
        let url = URL(string: "\(apiURL)/locations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let locationData = LocationData(
            NAME: name,
            ZIPCODE: zipcode,
            CITY: city,
            STREET: street,
            STREETNUMBER: streetNumber
        )

        guard let encoded = try? JSONEncoder().encode(locationData) else {
            print("Failed to encode location data")
            return
        }

        request.httpBody = encoded
            

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error adding location: \(error)")
                return
            }

            guard let data = data, let locationResponse = try? JSONDecoder().decode(LocationResponse.self, from: data) else {
                print("Invalid response")
                return
            }

            DispatchQueue.main.async {
                self.allLocations.append(locationResponse.data)
                self.name = ""
                self.street = ""
                self.streetNumber = ""
                self.zipcode = ""
                self.city = ""
                self.showAddLocation = false
            }

        }.resume()

    }

    private func loadLocations() {
        let url = URL(string: "\(apiURL)/locations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching locations: \(error)")
                return
            }

            guard let data = data else {
                return
            }

            do {
                let locationresponse = try JSONDecoder().decode(
                    LocationsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.allLocations = locationresponse.data
                }
            } catch {
                print("Error decoding locations: \(error)")
            }

        }.resume()
    }
}

struct LocationView: View {
    @State var location: Location
    @State private var editableLocation: EditableLocation
    @State private var updateSuccess = false

    init(location: Location) {
        self.location = location
        self._editableLocation = State(
            initialValue: EditableLocation(from: location))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Location Details").font(.subheadline)
                        .foregroundColor(.secondary)
                ) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                            .padding(.trailing)
                        Spacer()
                        TextField("Name", text: $editableLocation.NAME)
                            .textFieldStyle(DefaultTextFieldStyle())
                    }
                }

                Section(
                    header: Text("Address").font(.subheadline).foregroundColor(
                        .secondary)
                ) {
                    TextField("Street", text: $editableLocation.STREET)
                        .textFieldStyle(DefaultTextFieldStyle())

                    TextField(
                        "Street Number", text: $editableLocation.STREETNUMBER
                    )
                    .textFieldStyle(DefaultTextFieldStyle())
                    .keyboardType(.numberPad)

                    TextField("Zipcode", text: $editableLocation.ZIPCODE)
                        .textFieldStyle(DefaultTextFieldStyle())

                    TextField("City", text: $editableLocation.CITY)
                        .textFieldStyle(DefaultTextFieldStyle())
                }

                Button(action: saveLocation) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(Color.accentColor)
                        Spacer()
                    }
                }
                .popover(isPresented: $updateSuccess) {
                    VStack {
                        Text("Location updated successfully")
                            .font(.headline)
                    }
                }
                .padding()
                .cornerRadius(10)
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveLocation() {
        let url = URL(string: "http://localhost:8000/locations/\(location.ID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let locationData = LocationData(
            NAME: editableLocation.NAME,
            ZIPCODE: editableLocation.ZIPCODE,
            CITY: editableLocation.CITY,
            STREET: editableLocation.STREET,
            STREETNUMBER: editableLocation.STREETNUMBER
        )

        guard let encoded = try? JSONEncoder().encode(locationData) else {
            print("Failed to encode location data")
            return
        }
        request.httpBody = encoded

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error saving location: \(error)")
                return
            }

            guard let data = data,
                let locationResponse = try? JSONDecoder().decode(
                    LocationUpdate.self, from: data)
            else {
                print("Invalid response")
                return
            }

            let locationResult = locationResponse.result

            DispatchQueue.main.async {
                self.location = locationResult
                self.editableLocation = EditableLocation(from: locationResult)
                self.updateSuccess = true
            }
        }.resume()
    }


    struct EditableLocation {
        var NAME: String
        var ZIPCODE: String
        var CITY: String
        var STREET: String
        var STREETNUMBER: String

        init(from location: Location) {
            self.NAME = location.NAME
            self.ZIPCODE = location.ZIPCODE
            self.CITY = location.CITY
            self.STREET = location.STREET
            self.STREETNUMBER = location.STREETNUMBER
        }
    }
}
