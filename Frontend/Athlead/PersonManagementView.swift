//
//  PersonManagementView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//


import SwiftUI

struct PersonManagementView: View {
    
    
    @State private var personsContestants: [Person] = []
    @State private var personsJudges: [Person] = []
    @State private var personsAdmins: [Person] = []
    
    @State private var showAddPersonSheet = false
    @State private var personToEdit: Person? = nil
    
    @State private var isLoading: Bool = false
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
                        if personsAdmins.isEmpty {
                            Text("No administrators available.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            ForEach(personsAdmins) { Person in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(Person.FIRSTNAME) \(Person.LASTNAME)")
                                            .font(.headline)
                                        Text(Person.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(Person.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = Person
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
                            ForEach(personsJudges) { Person in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(Person.FIRSTNAME) \(Person.LASTNAME)")
                                            .font(.headline)
                                        Text(Person.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(Person.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = Person
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
                            ForEach(personsContestants) { Person in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(Person.FIRSTNAME) \(Person.LASTNAME)")
                                            .font(.headline)
                                        Text(Person.EMAIL)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Role: \(Person.ROLE)")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Button(action: {
                                        personToEdit = Person
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
        
        fetch("persons", PersonsResponse.self) { result in
            switch result {
            case .success(let persons):
                for person in persons.data {
                    if person.ROLE.lowercased() == "admin" {
                        if !personsAdmins.contains(person) {
                            personsAdmins.append(person)
                        }
                    } else if person.ROLE.lowercased() == "judge" {
                        if !personsJudges.contains(person) {
                            personsJudges.append(person)
                        }
                    } else {
                        if !personsContestants.contains(person) {
                            personsContestants.append(person)
                        }
                    }
                }
                isLoading = false
            case .failure(let error):
                print("Error fetching persons: \(error)")
                isLoading = false
                errorMessageLoad = "Failed to fetch persons"
            }
            
        }
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
    
    private func addPerson(person: Person) {
        if person.ROLE.uppercased() == "ADMIN" {
            if !personsAdmins.contains(person) {
                personsAdmins.append(person)
            }
        } else if person.ROLE.uppercased() == "JUDGE" {
            if !personsJudges.contains(person) {
                personsJudges.append(person)
            }
        } else {
            if !personsContestants.contains(person) {
                personsContestants.append(person)
            }
        }
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
    @State private var selectedGender: String = "Male"
    @State private var selectedPic: Bool = true
    @State private var password: String = ""
    
    
    private let possibleRoles: [String] = ["Admin", "Judge", "Contestant"]
    
    var onAddVoid: (Person) -> Void
    
    private func onAdd(person: Person) {
        
        
        let person = PersonCreate(first_name: person.FIRSTNAME,
                                  last_name: person.LASTNAME,
                                  gender: selectedGender,
                                  email: person.EMAIL,
                                  phone: person.PHONE,
                                  birth_year: person.BIRTH_YEAR,
                                  grade: person.GRADE,
                                  role: person.ROLE.uppercased(),
                                  pics: selectedPic ? 1 : 0,
                                  disabilities: "",
                                  password: password)
        
        fetch("persons", PersonCreateResponse.self, "POST", nil, person) { result in
            switch result {
            case .success(let person):
                onAddVoid(person.data)
            case .failure(let error):
                print("Error adding person: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Password", text: $password)
                        .textContentType(.password)
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
                    
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(["Male","Female","Diverse"], id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Role", selection: $selectedRole) {
                        ForEach(possibleRoles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Allow to take pictures", isOn: $selectedPic)
                    
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
                        let newPerson = Person(
                            ID: UUID().uuidString,
                            FIRSTNAME: firstName,
                            LASTNAME: lastName,
                            EMAIL: email,
                            PHONE: phone,
                            BIRTH_YEAR: birthyear,
                            GRADE: grade,
                            ROLE: selectedRole,
                            PICS: 1,
                            GENDER: "1",
                            DISABILITIES: ""
                        );
                        onAdd(person: newPerson)
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || selectedRole.isEmpty)
                }
            }
        }
    }
}
