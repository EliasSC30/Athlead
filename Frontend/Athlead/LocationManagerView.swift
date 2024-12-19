//
//  LocationManagerView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct LocationManagerView: View {

    @State private var allLocations: [Location] = []
    @State private var showAddLocation = false

    @State private var name = ""
    @State private var street = ""
    @State private var streetNumber = ""
    @State private var zipcode = ""
    @State private var city = ""
    
    @State private var isLoading: Bool = true
    @State private var errorMessageLoad: String?

    var body: some View {
        VStack {
            Group {
                if isLoading {
                    ProgressView("Loading Location data...")
                } else if let error = errorMessageLoad {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
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
                            
                        }
                        
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
                                            
                                            Button(action: {
                                                Task {
                                                    await createLocation()
                                                }
                                            }) {
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
            }.onAppear {
                Task {
                    await loadLocations()
                }
            }
            .navigationBarItems(trailing: Button(action: {
                Task {
                    await loadLocations()
                }
            }) {
                    Image(systemName: "arrow.clockwise")
                })
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
    
    private func createLocation() async {
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
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                let locationData = try JSONDecoder().decode(LocationResponse.self, from: data)
                allLocations.append(locationData.data)
                name = ""
                street = ""
                streetNumber = ""
                zipcode = ""
                city = ""
                showAddLocation = false
            default:
                break
            }
        } catch {
            print("Error fetching locations: \(error)")
        }
    }

    private func loadLocations() async {
        isLoading = true
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
                allLocations = locationData.data
                isLoading = false
                errorMessageLoad = nil
            default:
                break
            }
        } catch {
            errorMessageLoad = "Error fetching locations"
            print("Error fetching locations: \(error)")
        }
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

                Button(action: {
                    Task{
                        await saveLocation()
                    }}) {
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

    private func saveLocation() async {
        let url = URL(string: "\(apiURL)/locations/\(location.ID)")!
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
        
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                let locationData = try JSONDecoder().decode(LocationUpdate.self, from: data)
                
                location = locationData.result
                editableLocation = EditableLocation(from: location)
                updateSuccess = true
                
            default:
                break
            }
        } catch {
            print("Error fetching locations: \(error)")
        }
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
