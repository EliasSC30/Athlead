//
//  SportfestOverview.swift
//  Athlead
//
//  Created by Wichmann, Jan on 12.12.24.
//


import SwiftUI
import MapKit

struct SportfestOverview: View {
    var sportfestID: String

    @State private var sportfest: SportfestData?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let classes = ["1A", "1B", "2A", "2B", "3A", "3B", "4a", "4b"]
    let contests = ["Weitwurf", "Weitsprung", "Sprint", "Staffellauf"]
    @State private var eventDuration = ""
    @State private var locationName = "Central Sports Park"
    @State private var coordinate = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedClass: String? = nil
    @State private var showClassDetails = false

    var body: some View {
            Group {
                if isLoading {
                    ProgressView("Loading Sportfest")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    ScrollView {
                        VStack(alignment: .center, spacing: 30) {
                            // Hero Section
                            VStack(spacing: 10) {
                                Text("🏅 sportfest.name")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("sportfest.description")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                Text("\(eventDuration) at \(locationName)")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                            ZStack {
                                Map(coordinateRegion: $region, annotationItems: [Annotation(coordinate: coordinate)]) { annotation in
                                    MapMarker(coordinate: annotation.coordinate, tint: .blue)
                                }
                                .frame(height: 250)
                                .cornerRadius(20)
                                .shadow(radius: 10)

                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(locationName)
                                            .font(.caption)
                                            .padding(8)
                                            .background(Color.black.opacity(0.6))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .padding(10)
                                    }
                                }
                            }

                            // Contestant Classes Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("🎓 Contestant Classes")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 20)]) {
                                    ForEach(classes, id: \ .self) { className in
                                        Text(className)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                            .onTapGesture {
                                                selectedClass = className
                                                showClassDetails.toggle()
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Contest Categories Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("🏃‍♂️ Contests")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)]) {
                                    ForEach(contests, id: \ .self) { contest in
                                        Text(contest)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .navigationTitle("Sportfest Overview")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: $showClassDetails) {
                        if let selectedClass = selectedClass {
                            ClassDetailView(className: selectedClass)
                        }
                    }
                }
            }.onAppear(perform: loadSportfestData)
        }

    struct Annotation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }

    func loadSportfestData() {
        isLoading = true
        errorMessage = nil

        let url = URL(string: apiURL + "/sportfests/\(sportfestID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch sportfest: \(error.localizedDescription)"
                    return
                }
            }
            guard let data = data, let sportfestResponse = try? JSONDecoder().decode(SportFestSingleResponse.self, from: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to decode sportfest."
                }
                return
            }

            DispatchQueue.main.async {
                self.locationName = sportfestResponse.data.location_name

                let address = sportfestResponse.data.location_zipcode + " " + sportfestResponse.data.location_city + ", " + sportfestResponse.data.location_street + " " + sportfestResponse.data.location_street_number
                let geoCoder = CLGeocoder()

                geoCoder.geocodeAddressString(address) { (placemarks, error) in
                    guard let placemarks = placemarks, let location = placemarks.first?.location else {
                        print("Error converting address to coordinates: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    self.coordinate = location.coordinate
                    self.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = TimeZone(abbreviation: "UTC")

                let endDate = formatter.date(from: sportfestResponse.data.details_start) ?? Date()
                let startDate = formatter.date(from: sportfestResponse.data.details_start) ?? Date()

                self.eventDuration = "\(startDate.formatted()) - \(endDate.formatted())"

                self.sportfest = sportfestResponse.data
                self.isLoading = false
                self.errorMessage = nil
            }
        }.resume()
    }
}

struct ClassDetailView: View {
    let className: String

    let people = ["John Doe", "Jane Smith", "Alice Johnson", "Bob Brown", "Charlie Davis"]
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Details for \(className)")
                .font(.largeTitle)
                .fontWeight(.bold)

            // People Section
            VStack(alignment: .leading, spacing: 10) {
                Text("👥 People")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                TextField("Search people", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 10)

                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(people.filter { searchText.isEmpty || $0.localizedCaseInsensitiveContains(searchText) }, id: \ .self) { person in
                        Text(person)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .padding(.horizontal)

            Button("Dismiss") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    @Environment(\ .dismiss) var dismiss
}
