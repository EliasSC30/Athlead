//
//  ManageSportfests.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct ManageSportfests: View {

    let apiURL = "http://localhost:8000"
    
    @State var oldSportFests: [SportFestDisplay] = []
    @State var currentSportFests: [SportFestDisplay] = []
    @State var newSportfests: [SportFestDisplay] = []
    
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Current Sportfests")) {
                    if currentSportFests.isEmpty {
                        Text("No current sportfests available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(currentSportFests, id: \.self) { sportfest in
                            NavigationLink(
                               destination: Text("Details for \(sportfest.NAME)")
                            ) {
                                Label(
                                    sportfest.NAME,
                                    systemImage: "figure.disc.sports")
                            }
                        }.onDelete(perform: {
                            indexSet in
                            let index = indexSet.first!
                            let sportfest = currentSportFests[index]
                            deleteSportfests(sportFest: sportfest)
                        })
                    }

                }
                
                Section(header: Text("Upcoming Sportfests")) {
                    if newSportfests.isEmpty {
                        Text("No upcoming sportfests available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(newSportfests, id: \.self) { sportfest in
                            NavigationLink(
                               destination: Text("Details for \(sportfest.NAME)")
                            ) {
                                Label(
                                    sportfest.NAME,
                                    systemImage: "figure.run")
                            }
                        }.onDelete(perform: {
                            indexSet in
                            let index = indexSet.first!
                            let sportfest = newSportfests[index]
                            deleteSportfests(sportFest: sportfest)
                        })
                    }

                }
            
                Section(header: Text("Past Sportfests")) {
                    if oldSportFests.isEmpty {
                        Text("No past sportfests available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(oldSportFests, id: \.self) { sportfest in
                            NavigationLink(
                               destination: Text("Details for \(sportfest.NAME)")
                            ) {
                                Label(
                                    sportfest.NAME,
                                    systemImage: "flag.pattern.checkered")
                            }
                        }.onDelete(perform: {
                            indexSet in
                            let index = indexSet.first!
                            let sportfest = oldSportFests[index]
                            deleteSportfests(sportFest: sportfest)
                        })
                    }

                }

            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Sportfests")
        }.onAppear(perform: loadSportFests)
    }
    
    private func loadSportFests(){
        let url = URL(string: "\(apiURL)/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching sportfests: \(error)")
                return
            }
            
            guard let data = data, let sportfestsResponse = try? JSONDecoder().decode(SportFestsResponse.self, from: data) else {
                print("Failed to decode sportfests")
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
                        return
                    }
                    guard let data = data, let detailsResponse = try? JSONDecoder().decode(DetailsResponse.self, from: data) else {
                        print("Failed to decode details")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        let formatter = DateFormatter()
                        
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        formatter.timeZone = TimeZone(abbreviation: "UTC")
                        
                        let endDate = formatter.date(from: detailsResponse.data.END) ?? Date()
                        let startDate = formatter.date(from: detailsResponse.data.START) ?? Date()
                        
                        let sportfest = SportFestDisplay(ID: sportfest.id, DETAILS_ID: sportfest.details_id, CONTACTPERSON_ID: detailsResponse.data.CONTACTPERSON_ID, NAME: detailsResponse.data.NAME, LOCATION_ID: detailsResponse.data.LOCATION_ID, START: startDate, END: endDate)
                        
                        if endDate < Date() {
                            if currentSportFests.contains(sportfest) {
                                currentSportFests.removeAll(where: { $0 == sportfest })
                            }
                            if newSportfests.contains(sportfest) {
                                newSportfests.removeAll(where: { $0 == sportfest })
                            }
                            if !oldSportFests.contains(sportfest) {
                                oldSportFests.append(sportfest)
                            }
                        } else if endDate > Date() && startDate < Date() {
                            if oldSportFests.contains(sportfest) {
                                oldSportFests.removeAll(where: { $0 == sportfest })
                            }
                            if newSportfests.contains(sportfest) {
                                newSportfests.removeAll(where: { $0 == sportfest })
                            }
                            if !currentSportFests.contains(sportfest) {
                                currentSportFests.append(sportfest)
                            }
                        } else {
                            if currentSportFests.contains(sportfest) {
                                currentSportFests.removeAll(where: { $0 == sportfest })
                            }
                            if oldSportFests.contains(sportfest) {
                                oldSportFests.removeAll(where: { $0 == sportfest })
                            }
                            if !newSportfests.contains(sportfest) {
                                newSportfests.append(sportfest)
                            }
                        }
                            
                            
                        
                        
                    }
                }.resume()
                
            }
            
        }.resume()
        
        
    }
    
    private func deleteSportfests(sportFest: SportFestDisplay){
        
            
    }
}
