//
//  PersonManagementView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//


import SwiftUI

struct PersonManagementView: View {
    
    let apiURL = "http://localhost:8000"
    
    
    @State private var personsContestants: [PersonDisplay] = []
    @State private var personsJudges: [PersonDisplay] = []
    @State private var personsAdmins: [PersonDisplay] = []
    
    @State private var showAddPersonSheet = false
    @State private var personToEdit: PersonDisplay? = nil
    
    @State private var isLoading: Bool = true
    @State private var errorMessageLoad: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Person data...")
            } else if let error = errorMessageLoad {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                List {
                    Section("Administrators") {
                        if personsJudges.isEmpty {
                            Text("No administrators available.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            ForEach(personsAdmins) { personDisplay in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(personDisplay.CONTACT.FIRSTNAME) \(personDisplay.CONTACT.LASTNAME)")
                                            .font(.headline)
                                        Text(personDisplay.CONTACT.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(personDisplay.PERSON.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = personDisplay
                                    }) {
                                        Text("Edit")
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                            .onDelete(perform: deletePerson)
                        }
                    }
                    Section("Judges") {
                        if personsJudges.isEmpty {
                            Text("No judges available.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            ForEach(personsJudges) { personDisplay in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(personDisplay.CONTACT.FIRSTNAME) \(personDisplay.CONTACT.LASTNAME)")
                                            .font(.headline)
                                        Text(personDisplay.CONTACT.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(personDisplay.PERSON.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = personDisplay
                                    }) {
                                        Text("Edit")
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                            .onDelete(perform: deletePerson)
                        }
                    }
                    Section("Contestants") {
                        if personsContestants.isEmpty {
                            Text("No contestants available.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            ForEach(personsContestants) { personDisplay in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(personDisplay.CONTACT.FIRSTNAME) \(personDisplay.CONTACT.LASTNAME)")
                                            .font(.headline)
                                        Text(personDisplay.CONTACT.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(personDisplay.PERSON.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = personDisplay
                                    }) {
                                        Text("Edit")
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                            .onDelete(perform: deletePerson)
                        }
                    }
                }
                .navigationTitle("Person Management")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddPersonSheet = true
                        }) {
                            Label("Add Person", systemImage: "plus")
                        }
                    }
                }
                .sheet(item: $personToEdit, onDismiss: clearEditPerson) { personDisplay in
                    //PersonEditView(personDisplay: personDisplay, onSave: updatePerson)
                }
                .sheet(isPresented: $showAddPersonSheet) {
                    PersonAddView(onAddVoid: addPerson)
                }
            }
        }.onAppear(perform: loadPersons)
            .navigationBarItems(trailing: Button(action: loadPersons) {
                Image(systemName: "arrow.clockwise")
            })
        
    }
    
    private func loadPersons(){
        isLoading = true
        errorMessageLoad = nil
        
        let url = URL(string: "\(apiURL)/persons")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("Error \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessageLoad = "Failed to fetch persons"
                }
                return
            }
            guard let data = data, let personResponse = try? JSONDecoder().decode(PersonsResponse.self, from: data) else {
                print("Coulnd decode")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessageLoad = "Failed to fetch persons"
                }
                return
            }
            
            let personData = personResponse.data;
            
            for person in personData {
                let contactInfoId = person.CONTACTINFO_ID
                let contactInfoUrl = URL(string: "\(apiURL)/contactinfos/\(contactInfoId)")!
                var request = URLRequest(url: contactInfoUrl)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessageLoad = "Failed to fetch persons"
                        }
                        return
                    }
                    guard let data = data, let contactInfoResponse = try? JSONDecoder().decode(ContactInfoResponse.self, from: data) else {
                        print("Coulnd decode")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessageLoad = "Failed to fetch persons"
                        }
                        return
                    }
                    
                    let person = PersonDisplay(ID: person.ID, PERSON: person, CONTACTINFO_ID: contactInfoId, CONTACT: contactInfoResponse.data)
                    
                    DispatchQueue.main.async {
                        if person.PERSON.ROLE.uppercased() == "ADMIN" {
                            if !personsAdmins.contains(person) {
                                personsAdmins.append(person)
                            }
                        } else if person.PERSON.ROLE.uppercased() == "JUDGE" {
                            if !personsJudges.contains(person) {
                                personsJudges.append(person)
                            }
                        } else {
                            if !personsContestants.contains(person) {
                                personsContestants.append(person)
                            }
                        }
                        self.isLoading = false
                        self.errorMessageLoad = nil
                        
                    }
                }.resume()
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessageLoad = nil
            }
        }.resume()
        
    }
    
    private func deletePerson(at offsets: IndexSet) {
        if personsAdmins.contains(personsAdmins[offsets.first!]) {
            personsAdmins.remove(atOffsets: offsets)
        } else if personsJudges.contains(personsJudges[offsets.first!]) {
            personsJudges.remove(atOffsets: offsets)
        } else {
            personsContestants.remove(atOffsets: offsets)
        }
    }
    
    private func addPerson(person: PersonDisplay) {
        print(person)
        if person.PERSON.ROLE.uppercased() == "ADMIN" {
            if !personsAdmins.contains(person) {
                personsAdmins.append(person)
            }
        } else if person.PERSON.ROLE.uppercased() == "JUDGE" {
            if !personsJudges.contains(person) {
                personsJudges.append(person)
            }
        } else {
            if !personsContestants.contains(person) {
                personsContestants.append(person)
            }
        }
    }
    
    private func updatePerson(person: PersonDisplay, role: String) {
        /*if let index = persons.firstIndex(where: { $0.ID == person.ID }) {
         persons[index] = person
         }*/
        clearEditPerson()
    }
    
    private func clearEditPerson() {
        personToEdit = nil
    }
}

// Add Person View
struct PersonAddView: View {
    @Environment(\.dismiss) var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var grade: String = ""
    @State private var birthyear: String = ""
    @State private var selectedRole: String = "Contestant" // Default role
    
    private let possibleRoles: [String] = ["Admin", "Judge", "Contestant"]
    
    var onAddVoid: (PersonDisplay) -> Void
    
    private func onAdd(personDisplay: PersonDisplay) {
        let url = URL(string: "http://localhost:8000/contactinfos")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let contactInfo = ContactInfoCreate(FIRSTNAME: personDisplay.CONTACT.FIRSTNAME, LASTNAME: personDisplay.CONTACT.LASTNAME, EMAIL: personDisplay.CONTACT.EMAIL, PHONE: personDisplay.CONTACT.PHONE, BIRTH_YEAR: personDisplay.CONTACT.BIRTH_YEAR, GRADE: personDisplay.CONTACT.GRADE)
        
        guard let encoded = try? JSONEncoder().encode(contactInfo) else {
            print("Failed to encode contact info")
            return
        }
        
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error \(error)")
                return
            }
            
            guard let data = data, let contactInfoResponse = try? JSONDecoder().decode(ContactInfoResponse.self, from: data) else {
                print("Coulnd decode by contactinfo")
                return
            }
            
            let person = PersonCreate(CONTACTINFO_ID: contactInfoResponse.data.ID, ROLE: personDisplay.PERSON.ROLE.uppercased())
            
            let url = URL(string: "http://localhost:8000/persons")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            guard let encoded = try? JSONEncoder().encode(person) else {
                print("Failed to encode person")
                return
            }
            
            request.httpBody = encoded
            
            if let string = String(data: encoded, encoding: .utf8) {
                print(string)
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error \(error)")
                    return
                }
                
                guard let data = data, let _ = try? JSONDecoder().decode(PersonResponse.self, from: data) else {
                    print("Coulnd decode by personResponse")
                    return
                }
                
                DispatchQueue.main.async {
                    print("Person added")
                    onAddVoid(personDisplay)
                }
                
                
            }.resume()
        }.resume()
        
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Additional Details")) {
                    TextField("Birth Year", text: $birthyear)
                        .keyboardType(.numberPad)
                    TextField("Grade", text: $grade)
                        .keyboardType(.numberPad)
                    
                    Picker("Role", selection: $selectedRole) {
                        ForEach(possibleRoles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Add Person")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newPersonDisplay = PersonDisplay(
                            ID: UUID().uuidString,
                            PERSON: Person(
                                ID: UUID().uuidString,
                                CONTACTINFO_ID: UUID().uuidString,
                                ROLE: selectedRole
                            ),
                            CONTACTINFO_ID: UUID().uuidString,
                            CONTACT: Contact(
                                ID: UUID().uuidString,
                                FIRSTNAME: firstName,
                                LASTNAME: lastName,
                                EMAIL: email,
                                PHONE: phone,
                                BIRTH_YEAR: birthyear,
                                GRADE: grade
                            )
                        )
                        onAdd(personDisplay: newPersonDisplay)
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || selectedRole.isEmpty)
                }
            }
        }
    }
}


// Edit Person View
struct PersonEditView: View {
    @Environment(\.dismiss) var dismiss
    @State var personDisplay: PersonDisplay
    var onSave: (PersonDisplay) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // TextField("First Name", text: "")
                //TextField("Last Name", text: "")
                //TextField("Email", text: "")
                //   .keyboardType(.emailAddress)
                // TextField("Role", text: "")
            }
            .navigationTitle("Edit Person")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(personDisplay)
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview
struct PersonManagementView_Previews: PreviewProvider {
    static var previews: some View {
        PersonManagementView()
    }
}
