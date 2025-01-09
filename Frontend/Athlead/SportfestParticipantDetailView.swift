//
//  SportfestParticipantDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 08.01.25.
//
import SwiftUI
import MapKit
import CoreLocation

struct SportfestParticipantDetailView: View {
    let sportfest: SportfestData
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var contests: [ContestData] = []
    
    @State private var showEventMap: Bool = false
    
    var body: some View {
        ScrollView {
                
                // Event Overview Section
                EventOverviewView(sportfest: sportfest, showEventMap: $showEventMap)
                

                Group {
                    // Loading State
                    if isLoading {
                        ProgressView("Loading more information...")
                            .padding()
                    }
                    // Error Message State
                    else if let errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    } else {
                        ForEach(contests) { contest in
                            ContestCardView(contest: contest, cts_wf: sportfest.cts_wf)
                                .padding(.horizontal)
                        }
                    }
                }
        }
        .onAppear(perform: fetchAllSpofestContests)
        .sheet(isPresented: $showEventMap) {
            EventMapView(sportfest: sportfest, showMapSheet: $showEventMap)
        }
    }
    
    func fetchAllSpofestContests() {
        isLoading = true
        errorMessage = nil
        let dispatchGroup = DispatchGroup()
        
        for contest in sportfest.cts_wf {
            let contestId = contest.contest_id
            dispatchGroup.enter()
            fetch("contests/\(contestId)", ContestResponse.self) { result in
                switch result {
                case .success(let resp):
                    DispatchQueue.main.async {
                        if !contests.contains(resp.data) {
                            contests.append(resp.data)
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            isLoading = false
            contests.sort { contest1, contest2 in
                let contest1Participates = sportfest.cts_wf.filter { $0.contest_id == contest1.ct_id }.first?.participates ?? false
                let contest2Participates = sportfest.cts_wf.filter { $0.contest_id == contest2.ct_id }.first?.participates ?? false
                return contest1Participates && !contest2Participates
            }
        }
        
    }
}

// Event Overview Section
struct EventOverviewView: View {
    let sportfest: SportfestData
    
    @Binding var showEventMap: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Event Overview")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text("Location:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text(sportfest.location_name)
                Text("\(sportfest.location_street) \(sportfest.location_street_number)")
                Text("\(sportfest.location_zipcode) \(sportfest.location_city)")
                //OPen sheet button
                Button(action: {
                    showEventMap.toggle()
                }) {
                    Text("Open Map")
                        .foregroundColor(.blue)
                        .font(.headline)
                        .padding(.top, 8)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                    Text("Contact Person:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Text("\(sportfest.cp_firstname) \(sportfest.cp_lastname)")
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                    Text("Phone: \(sportfest.cp_phone)")
                }
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.orange)
                    Text("Email: \(sportfest.cp_email)")
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                    Text("Event Details:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Image(systemName: "play.fill")
                        .foregroundColor(.blue)
                    Text("Start: \(formatDate(sportfest.details_start))")
                }
                HStack {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                    Text("End: \(formatDate(sportfest.details_end))")
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}


// Map Section
struct EventMapView: View {
    let sportfest: SportfestData
    
    @Binding var showMapSheet: Bool
    @State private var sportfestCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 0.0,
        longitude: 0.0
        )
    
    var body: some View {
        Map {
            Marker(sportfest.details_name, systemImage: "figure.wave", coordinate: sportfestCoordinate)
        }.onAppear(perform: loadCoordinate)
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                MapButtons(coordinate: sportfestCoordinate, showMapSheet: $showMapSheet)
                    .padding(.top)
                Spacer()
            }.background(.thinMaterial)
        }
    }
    
    
    func loadCoordinate() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString("\(sportfest.location_street) \(sportfest.location_street_number), \(sportfest.location_zipcode) \(sportfest.location_city)", completionHandler: {
            placemarks, error in
            let placemark = placemarks?.first
            let lat = placemark?.location?.coordinate.latitude
            let lon = placemark?.location?.coordinate.longitude
            sportfestCoordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        })
    }
}

struct MapButtons: View {
    
    let coordinate: CLLocationCoordinate2D
    
    @Binding var showMapSheet: Bool
    
    var body: some View {
        HStack {
            Button {
                openInMaps()
            } label: {
                Image(systemName: "map.fill")
                Text("Open in Maps")
            }.buttonStyle(.borderedProminent)
            
            //Close sheet button
            Button {
                showMapSheet.toggle()
            } label: {
                Image(systemName: "xmark")
                Text("Close")
            }.buttonStyle(.borderedProminent)
        }.labelStyle(.iconOnly)
    }
    
    func openInMaps() {
        let url = URL(string: "https://maps.apple.com/?q=\(coordinate.latitude),\(coordinate.longitude)")!
        UIApplication.shared.open(url)
    }
}

// Card view for individual contest
struct ContestCardView: View {
    let contest: ContestData
    let cts_wf: [ContestWithFlag]
    
    @State private var isCompeting: Bool = false;

    var body: some View {
        NavigationLink(destination: SportfestParticipantContestDetailView(contest: contest)){
            VStack(alignment: .leading, spacing: 12) {
                // Contest Title
                HStack {
                    Image(systemName: "rosette")
                        .foregroundColor(.blue)
                    Text(contest.ct_details_name)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text("Location: \(contest.ct_location_name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.purple)
                    Text("Date: \(formatDate(contest.ct_details_start)) - \(formatDate(contest.ct_details_end))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Competing Status
                HStack {
                    Image(systemName: isCompeting ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(isCompeting ? .green : .red)
                    Text(isCompeting ? "Competing" : "Not Competing")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(isCompeting ? .green : .red)
                }
                .padding(6)
                .background(isCompeting ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
            .padding(.vertical, 8)
            .onAppear(perform: {
                let contestParticipate = cts_wf.filter { $0.contest_id == contest.ct_id }.first
                isCompeting = contestParticipate!.participates
            })
        }.buttonStyle(PlainButtonStyle())
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
