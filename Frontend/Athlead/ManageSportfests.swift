//
//  ManageSportfests.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct ManageSportfests: View {
    
    @State var oldSportFests: [SportfestData] = []
    @State var currentSportFests: [SportfestData] = []
    @State var newSportfests: [SportfestData] = []
    
    @State private var isLoading: Bool = true
    @State private var errorMessageLoad: String?
    
    private let cacheKey = "cachedSportfests"
    private let cacheExpiryKey = "cacheExpiry"
    private let cacheDuration: TimeInterval = 60 // Cache valid for 1 minute
    
    var body: some View {
        VStack {
            Group {
                if isLoading {
                    ProgressView("Loading Sportfest data...")
                } else if let error = errorMessageLoad {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        Section(header: Text("Current Sportfests")) {
                            if currentSportFests.isEmpty {
                                Text("No current sportfests available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(currentSportFests, id: \.self) { sportfest in
                                    NavigationLink(
                                        destination: AdminSportfestDetailView(sportfest: sportfest)
                                    ) {
                                        Label(
                                            sportfest.details_name,
                                            systemImage: "figure.disc.sports")
                                    }
                                }.onDelete(perform: {
                                    indexSet in
                                    let index = indexSet.first!
                                    let sportfest = currentSportFests[index]
                                    //deleteSportfests(sportFest: sportfest)
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
                                        destination: AdminSportfestDetailView(sportfest: sportfest)
                                    ) {
                                        Label(
                                            sportfest.details_name,
                                            systemImage: "figure.run")
                                    }
                                }.onDelete(perform: {
                                    indexSet in
                                    let index = indexSet.first!
                                    let sportfest = newSportfests[index]
                                    //deleteSportfests(sportFest: sportfest)
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
                                        destination: AdminSportfestDetailView(sportfest: sportfest)
                                    ) {
                                        Label(
                                            sportfest.details_name,
                                            systemImage: "flag.pattern.checkered")
                                    }
                                }.onDelete(perform: {
                                    indexSet in
                                    let index = indexSet.first!
                                    let sportfest = oldSportFests[index]
                                    //deleteSportfests(sportFest: sportfest)
                                })
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Sportfests")
                }
            }.onAppear {
                Task {
                    await loadSportFests()
                }
            }
            .navigationBarItems(trailing: Button(action: {
                Task {
                    await loadSportFests(forceReload: true)
                }
            }) {
                Image(systemName: "arrow.clockwise")
            })
        }
    }
    
    private func loadSportFests(forceReload: Bool = false) async {
        isLoading = true
        errorMessageLoad = nil
        
        // Check cache
        if !forceReload, let cachedData = getCachedSportfests(), let cacheExpiry = UserDefaults.standard.object(forKey: cacheExpiryKey) as? Date {
            if Date() < cacheExpiry {
                // Use cached data if cache is still valid
                self.oldSportFests = cachedData.oldSportFests
                self.currentSportFests = cachedData.currentSportFests
                self.newSportfests = cachedData.newSportfests
                isLoading = false
                return
            }
        }
        
        // Cache is either expired or force reload, fetch fresh data
        let url = URL(string: "\(apiURL)/sportfests")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                guard let sportFestsResponse = try? JSONDecoder().decode(SportFestsResponse.self, from: data) else {
                    isLoading = false
                    errorMessageLoad = "Error decoding sport fests"
                    return
                }
                let sportFests = sportFestsResponse.data
                
                for sportfest in sportFests {
                    let startDate = stringToDate(sportfest.details_start)
                    let endDate = stringToDate(sportfest.details_end)
                    
                    
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
                
                
            case .failure:
                errorMessageLoad = "Error fetching sport fests"
            }
        } catch {
            errorMessageLoad = "Error fetching sport fests"
            print("Error fetching sport fests: \(error)")
        }
        
        isLoading = false
    }
    
    func stringToDate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: string) ?? Date()
    }
    
    // MARK: - Caching Functions
    private func cacheSportfests(old: [SportfestData], current: [SportfestData], new: [SportfestData]) {
        let sportfestsCache = CachedSportfests(oldSportFests: old, currentSportFests: current, newSportfests: new)
        if let cachedData = try? JSONEncoder().encode(sportfestsCache) {
            UserDefaults.standard.set(cachedData, forKey: cacheKey)
            UserDefaults.standard.set(Date().addingTimeInterval(cacheDuration), forKey: cacheExpiryKey)
        }
    }
    
    private func getCachedSportfests() -> CachedSportfests? {
        guard let cachedData = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(CachedSportfests.self, from: cachedData)
    }
}

struct CachedSportfests: Codable {
    let oldSportFests: [SportfestData]
    let currentSportFests: [SportfestData]
    let newSportfests: [SportfestData]
}
