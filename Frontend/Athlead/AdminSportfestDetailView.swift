//
//  AdminSportfestDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 19.12.24.
//
import SwiftUI

struct AdminSportfestDetailView: View {
    let sportfest: SportfestData
    @State private var showTemplateSheet = false
    @State private var contestTemplates: [CTemplate] = []
    @State private var selectedTemplate: CTemplate?
    
    @State private var isLoading: [Bool] = [false, false]
    @State private var errorMessage: String?
    @State private var contests: [ContestData] = []
    
    var body: some View {
        Group {
            if isLoading[0] || isLoading[1] {
                ProgressView("Loading sportfest data...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                NavigationView {
                    List {
                        // Sportfest Details
                        Section(header: Text("Sportfest Details")) {
                            DetailRow(title: "Name", value: sportfest.details_name)
                            DetailRow(title: "Start Date", value: formatDate(date: sportfest.details_start))
                            DetailRow(title: "End Date", value: formatDate(date: sportfest.details_end))
                        }
                        
                        // Contact Person Details
                        Section(header: Text("Contact Person")) {
                            DetailRow(title: "First Name", value: sportfest.cp_firstname)
                            DetailRow(title: "Last Name", value: sportfest.cp_lastname)
                            DetailRow(title: "Email", value: sportfest.cp_email)
                            DetailRow(title: "Phone", value: sportfest.cp_phone)
                        }
                        
                        // Location Details
                        Section(header: Text("Location")) {
                            DetailRow(title: "Name", value: sportfest.location_name)
                            DetailRow(title: "City", value: sportfest.location_city)
                            DetailRow(title: "Street", value: "\(sportfest.location_street) \(sportfest.location_street_number)")
                            DetailRow(title: "ZIP Code", value: sportfest.location_zipcode)
                        }
                        Section(header: Text("Contest Details")) {
                                                ForEach(contests, id: \.ct_details_id) { contest in
                                                    VStack(alignment: .leading) {
                                                        Text("Contest: \(contest.ct_details_name)")
                                                            .font(.headline)
                                                        DetailRow(title: "Name", value: contest.ct_details_name)
                                                        DetailRow(title: "Start Date", value: formatDate(date: contest.ct_details_start))
                                                        DetailRow(title: "End Date", value: formatDate(date: contest.ct_details_end))
                                                        DetailRow(title: "Location", value: contest.ct_location_name)
                                                        DetailRow(title: "Street", value: "\(contest.ct_street) \(contest.ct_streetnumber)")
                                                        DetailRow(title: "City", value: contest.ct_city)
                                                        DetailRow(title: "ZIP Code", value: contest.ct_zipcode)
                                                        DetailRow(title: "Contact Person", value: "\(contest.ct_cp_firstname) \(contest.ct_cp_lastname)")
                                                        DetailRow(title: "Email", value: contest.ct_cp_email)
                                                        DetailRow(title: "Phone", value: contest.ct_cp_phone)
                                                    }
                                                }
                                            }
                        // Contest Templates Section
                        Section {
                            Button(action: {
                                self.showTemplateSheet.toggle()
                            }) {
                                Text("Add Contest Template")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .navigationTitle(sportfest.details_name)
                    .listStyle(InsetGroupedListStyle())
                    .sheet(isPresented: $showTemplateSheet) {
                        TemplateSelectionView(contestTemplates: contestTemplates, selectedTemplate: $selectedTemplate, sportfest: sportfest, showTemplateSheet: $showTemplateSheet)
                    }
                }
            }
        }.onAppear {
            Task {
                await fetchData()
            }
        }
    }
    
    func formatDate(date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return formatter.date(from: date)?.formatted() ?? ""
    }
    
    private func fetchData() async {
        await fetchContests()
        await fetchCTemplates()
    }
    
    private func fetchContests() async {
        isLoading[0] = true
        errorMessage = nil
        
        let contestIds = sportfest.cts_wf
        if contestIds.isEmpty {
            isLoading[0] = false
            return
        }
        for contest in contestIds {
            let url = URL(string: "\(apiURL)/contests/\(contest.contest_id)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let result = try await executeURLRequestAsync(request: request)
                switch result {
                case .success(_, let data):
                    guard let decodedResponse = try? JSONDecoder().decode(ContestResponse.self, from: data) else {
                        isLoading[0] = false
                        errorMessage = "Failed to decode contests"
                        return
                    }
                    self.contests.append(decodedResponse.data)
                    isLoading[0] = false
                    errorMessage = nil
                case .failure(let error):
                    isLoading[0] = false
                    errorMessage = "Failed to fetch contests: \(error.localizedDescription)"
                }
            } catch {
                errorMessage = "Failed to fetch contests: \(error.localizedDescription)"
                isLoading[0] = false
            }
        }
    }
    
    private func fetchCTemplates() async {
        isLoading[1] = true
        errorMessage = nil
        let url = URL(string: apiURL + "/ctemplates")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                guard let decodedResponse = try? JSONDecoder().decode(CTemplatesResponse.self, from: data) else {
                    isLoading[1] = false
                    errorMessage = "Failed to decode contests"
                    return
                }
                contestTemplates = decodedResponse.data
                isLoading[1] = false
                errorMessage = nil
            case .failure(let error):
                isLoading[1] = false
                errorMessage = "Failed to fetch contests: \(error.localizedDescription)"
            }
        } catch {
            isLoading[1] = false
            errorMessage = "Error fetching contests: \(error)"
            print("Error creating template: \(error)")
        }

    
    }
}
struct TemplateSelectionView: View {
    let contestTemplates: [CTemplate]
    @Binding var selectedTemplate: CTemplate?
    let sportfest: SportfestData
    @Binding var showTemplateSheet: Bool
    
    var body: some View {
        NavigationView {
            List(contestTemplates) { template in
                NavigationLink(destination: ContestDetailsView(selectedTemplate: template, sportfest: sportfest, showTemplateSheet: $showTemplateSheet)) {
                    HStack {
                        Text(template.NAME)
                        if selectedTemplate?.id == template.id {
                            Spacer()
                            Text("Selected")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Select template")
            .navigationBarItems(leading: Button("Close") {
                showTemplateSheet = false
            })
        }
    }
}

// ContestDetailsView for inputting contest details
struct ContestDetailsView: View {
    var selectedTemplate: CTemplate
    let sportfest: SportfestData
    @State private var contestName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var location: Location?
    @State private var locations: [Location] = []
    @State private var isLoading: [Bool] = [false, false]
    @State private var admins: [Person] = []
    @State private var selectedAdmin: Person?
    @State private var errorMessage: String?
    @Binding var showTemplateSheet: Bool
    
    private let truncateLimit = 20

    var body: some View {
            Form {
                Section(header: Text("Contest Details")) {
                    HStack {
                        Text("Name")
                            .foregroundColor(.secondary)
                            .padding(.trailing)
                        Spacer()
                        TextField("Weitwurf (Frauen, 4b)", text: $contestName)
                            .textFieldStyle(DefaultTextFieldStyle())
                    }.padding(.vertical, 4)
                    
                    DatePicker("Start Date", selection: $startDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.bottom)
                    
                    DatePicker("End Date", selection: $endDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.bottom)
                    
                    Picker("Select Location", selection: $location) {
                        ForEach(locations, id: \.self) { location in
                            Text("\(location.NAME) - \(location.CITY)".truncated(to: truncateLimit))
                                .tag(location as Location)
                        }
                    }
                    
                    Picker("Select Admin", selection: $selectedAdmin) {
                        ForEach(admins, id: \.self) { admin in
                            Text("\(admin.FIRSTNAME) \(admin.LASTNAME)".truncated(to: truncateLimit))
                                .tag(admin as Person)
                        }
                    }
                }
                
                // Navigation to the next step (select helper)
                NavigationLink(destination: HelperSelectionView(contestName: contestName, startDate: startDate, endDate: endDate, location: location, sportfest: sportfest, ctemplate: selectedTemplate, admin: selectedAdmin, showTemplateSheet: $showTemplateSheet)) {
                    Text("Next Step: Select Helper")
                        
                }
                .disabled(contestName.isEmpty)
            }
            .navigationBarTitle(Text(selectedTemplate.NAME), displayMode: .inline)
            .onAppear {
                Task {
                    await fetchData()
                }
            }
    }
    
    private func fetchData() async {
        await fetchLocations()
        await fetchAdmins()
    }
    
    private func fetchAdmins() async {
        isLoading[0] = true
        errorMessage = nil
        
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
                
                admins = persons
                selectedAdmin = admins.first
                isLoading[0] = false
                errorMessage = nil
            default:
                break
            }
        } catch {
            errorMessage = "Error fetching contactpersons"
            print("Error fetching locations: \(error)")
        }
    }
    
    private func fetchLocations() async {
        isLoading[1] = true
        errorMessage = nil
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
                location = locations.first
                isLoading[1] = false
                errorMessage = nil
            default:
                break
            }
        } catch {
            print("Error fetching locations: \(error)")
        }
    }
}

struct HelperSelectionView: View {
    var contestName: String
    var startDate: Date
    var endDate: Date
    var location: Location?
    let sportfest: SportfestData
    let ctemplate: CTemplate
    let admin: Person?
    @Binding var showTemplateSheet: Bool
    
    
    @State private var isFinished = false
    @State private var isLoading = false
    @State private var message: String?
    
    @State private var selectedHelpers: Set<Person> = []  // Changed to a Set to hold multiple helpers
    @State private var helpers: [Person] = []
    
    var body: some View {
        Form {
            Section(header: Text("Select Helpers")) {
                // Use a List with ForEach to display helpers and allow multi-selection
                List(helpers, id: \.self) { helper in
                    MultipleSelectionRow(
                        title: helper.FIRSTNAME,
                        isSelected: selectedHelpers.contains(helper),
                        action: {
                            if selectedHelpers.contains(helper) {
                                selectedHelpers.remove(helper)
                            } else {
                                selectedHelpers.insert(helper)
                            }
                        }
                    )
                }
                
                Button("Confirm Helpers") {
                    Task {
                        await createContest()
                    }
                }
                .disabled(selectedHelpers.isEmpty)
            }
            // Status message if creation was successful
            if isFinished && !isLoading {
                Section {
                    if let message = message {
                        Text(message)
                            .foregroundColor(.green)
                        //Button Close Navigation
                        Button("Close") {
                            showTemplateSheet = false
                        }
                    } else {
                        ProgressView("Creating Contest...")
                    }
                }
            }
        }
        .navigationBarTitle("Select Helpers", displayMode: .inline)
                
        .onAppear {
            Task {
                await fetchHelpers()
            }
        }
    }
    
    private func createContest() async {
        isLoading = true
        isFinished = false
        message = nil
        
        let url = URL(string: "\(apiURL)/sportfests/\(sportfest.sportfest_id)/contests")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let helperIDs = selectedHelpers.map { $0.ID }
        
        let contestData = AssignContestSportFestCreate(LOCATION_ID: location!.ID, CONTACTPERSON_ID: admin!.ID, C_TEMPLATE_ID: ctemplate.ID, NAME: contestName, START: String(startDate.ISO8601Format().dropLast()), END: String(endDate.ISO8601Format().dropLast()), HELPERS: helperIDs)
    
        
        request.httpBody = try? JSONEncoder().encode(contestData)
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(let response, let data):
                print(response)
                print(data)
                
                if let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
                isFinished = true
                isLoading = false
                message = "Contest created successfully"
            case .failure(let error):
                isLoading = false
                isFinished = true
                message = "Error creating contest: \(error)"
            }
        } catch {
            isLoading = false
            isFinished = true
            message = "Error creating contest: \(error)"
        }
    
    }
    
    private func fetchHelpers() async {
        let url = URL(string: "\(apiURL)/persons")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let result = try await executeURLRequestAsync(request: request)
            switch result {
            case .success(_, let data):
                let helperData = try JSONDecoder().decode(PersonsResponse.self, from: data)
                helpers = helperData.data
            default:
                break
            }
        } catch {
            print("Error fetching helpers: \(error)")
        }
    }
}

// A reusable row view for each helper with a toggle to select/unselect
struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .onTapGesture {
                    action()
                }
        }
    }
}


// MARK: - Helper Views
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
