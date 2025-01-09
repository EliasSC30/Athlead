//
//  EventDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI
import MapKit
import EventKit

struct Contest: Identifiable {
    let id: String
    let detailsID: String
    let contestResultID: String
}

struct EventDetailView: View {
    let id: String
    let name: String
    let start: Date
    let end: Date
    let locationID: String
    let contactPersonID: String
    let detailsID: String
    let contests: [Contest] = []
    
    
    @State private var eventStore = EKEventStore()
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    @State private var showAddEventPopover = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Event Name
                Text(name)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.top, 10)
                    .accessibilityAddTraits(.isHeader)
                
                // Event Duration
                Text("\(formattedDate(start)) - \(formattedDate(end))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                // Map View
                Map
                {
                    Marker(name, coordinate: region.center)
                }
                
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .onAppear { fetchLocation() }
                .padding(.horizontal)
                
                // Contests Section
                
                Section(header: Text("Contests")) {
                    if contests.isEmpty {
                        VStack {
                            Text("No contests available")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(contests) { contest in
                            NavigationLink(destination: ContestDetailView()) {
                                HStack {
                                    Image(systemName: "flag.fill")
                                        .foregroundColor(.blue)
                                    Text(contest.detailsID)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                    
                }
                .padding(.vertical, 10)
                
                
                Section(header: Text("Details")) {
                    // Add to Calendar Button
                    Button(action: addEventToCalendar) {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .popover(isPresented: $showAddEventPopover) {
                        VStack {
                            Text("Event added to calendar")
                                .font(.headline)
                        }
                    }
                    
                    // Contact Person Button
                    ContactPersonCard(firstName: "John", lastName: "Doe", phone: "123456789", email: "john@doe.com")
                }
                .padding(.bottom)
                .padding(.top)
            }
            .padding(.top, 20)
            .padding(.horizontal)
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func fetchLocation() {
        let url = URL(string: apiURL + "/locations/"+String(locationID))!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error fetching location: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let locationResponse = try? JSONDecoder().decode(LocationResponse.self, from: data) else {
                print("Invalid response")
                return
            }
            
            let location = locationResponse.data;
            
            let address = "\(location.STREET) \(location.STREETNUMBER), \(location.ZIPCODE) \(location.CITY)"
            
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(address) { placemarks, error in
                
                if let error = error {
                    print("Error converting address to coordinates: \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("No placemarks found")
                    return
                }
                
                let coordinate = placemark.location?.coordinate
                region = MKCoordinateRegion(center: coordinate!, span: MKCoordinateSpan(latitudeDelta: 0.00, longitudeDelta: 0.00))
            }
            
            
            
        }.resume()
    }
    
    func addEventToCalendar() {
        
        
        eventStore.requestWriteOnlyAccessToEvents() { (granted, error) in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = name
                event.startDate = start
                event.endDate = end
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                    showAddEventPopover = true
                    
                } catch {
                    print("Error saving event: \(error.localizedDescription)")
                    showAddEventPopover = false
                }
            } else {
                showAddEventPopover = false
                print("Access denied to write events")
            }
        }
    }
    
    func contactPerson() {
        // Simulate contacting the person
        print("Contacting \(contactPersonID)")
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventDetailView(
                id: "event1",
                name: "Sports Event",
                start: Date(),
                end: Date().addingTimeInterval(3600),
                locationID: "location1",
                contactPersonID: "John Doe",
                detailsID: "details1"
            )
        }
    }
}
