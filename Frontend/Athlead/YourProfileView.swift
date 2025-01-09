//
//  YourProfileView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//

import SwiftUI

private let arrayOfDisabilitiesPerChild: [String] = ["accessibility", "hand.raised", "heart.fill", "heart.text.clipboard.fill", "bolt.heart.fill"]

var changeNr = 0;

func updateMsgs(){
    changeNr += 1;
    print("Changed")
}

struct YourProfileView: View {
    let loggedOut: () -> Void
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var children: [Person] = []
    @State private var profilePicture: String = ""
    
    @State private var loggedInUser: Person = User!
    @State private var isParent: Bool = false
    
    @State private var reloadPage: Bool = false
<<<<<<< Updated upstream
    
=======

    @State private var client: WebSocketClient = WebSocketClient();

>>>>>>> Stashed changes
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Checking your account type...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    if client.receivedMessages.isEmpty{}else{
                        ForEach(client.receivedMessages, id: \.self){
                            message in
                            Text("Next message: \(message)")
                        }
                    }
                    List {
                        // Profile Section
                        Section(header: Text("Your Profile")) {
                            HStack {
                                if profilePicture.isEmpty{
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 10)
                                } else {
                                    Base64ImageView(base64String: profilePicture);
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("\(loggedInUser.FIRSTNAME) \(loggedInUser.LASTNAME)")
                                        .font(.headline)
                                    Text("\(loggedInUser.GRADE ?? loggedInUser.ROLE)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Button (action: {
                                User = nil;
                                logout()
                            }){
                                Label("Log Out", systemImage: "arrowshape.turn.up.backward")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        if isParent {
                            Section(header: Text("Meine Kinder")) {
                                ForEach(children, id: \.self) { child in
                                    NavigationLink(destination: ChildProfileView(child: child, children: $children)) {
                                        HStack {
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.blue)
                                                .padding(.trailing, 10)
                                            VStack(alignment: .leading) {
                                                Text("\(child.FIRSTNAME) \(child.LASTNAME)")
                                                    .font(.headline)
                                                Text("\(child.GRADE ?? "No grade")")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Stats and site like
                        if !isParent {
                            Section(header: Text("Settings")) {
                                NavigationLink(destination: UploadPhotoView(onPicChanged: {(pic: String) -> Void in profilePicture = pic})){
                                    Label("Edit Profile Picture", systemImage: "pencil")
                                }
                            }
                        }
                        
                        // More Info Section
                        Section(header: Text("More")) {
                            NavigationLink(destination: ContactSupportView()) {
                                Label("Contact Support", systemImage: "envelope")
                            }
                            NavigationLink(destination: DatenschutzView()) {
                                Label("Datenschutz", systemImage: "lock.iphone")
                            }
                            NavigationLink(destination: ImpressumView()) {
                                Label("Impressum", systemImage: "lock.shield")
                            }
                            NavigationLink(destination: AboutTheAppView()) {
                                Label("About", systemImage: "info.circle")
                            }
                        }
                        
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("Profil")
                }
            }
<<<<<<< Updated upstream
        }.onAppear(perform: loadData)
        
=======
        }
        .onAppear(perform: loadData)
>>>>>>> Stashed changes
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        fetch("parents/children", ParentsChildrenResponse.self){ result in
            switch result {
            case .success(let resp):
                children = resp.data
                isParent = !children.isEmpty
                
            case .failure(let err): errorMessage = err.localizedDescription
            }
            isLoading = false
        }
<<<<<<< Updated upstream
        
        fetch("photos/"+User.unsafelyUnwrapped.ID, Photo.self){ result in
            switch result{
            case .success(let photo): profilePicture = photo.data
            case .failure( _): print("Could not get profile picture")
            }
        }
        
=======

                            fetch("photos/"+User.unsafelyUnwrapped.ID, Photo.self){ result in
                                switch result{
                                case .success(let photo): profilePicture = photo.data
                                case .failure(let _): print("Could not get profile picture")
                                }
                            }
        
        client.connect();

>>>>>>> Stashed changes
    }
    
    func logout(){
        // Remove cookies stored in memory
        clearCookies()
        
        // Delete the persistent cookies file
        do {
            if FileManager.default.fileExists(atPath: getCookieFilePath().path()) {
                try FileManager.default.removeItem(at: getCookieFilePath())
                print("Cookies file deleted.")
            } else {
                print("No cookies file found to delete.")
            }
        } catch {
            print("Failed to delete cookies file: \(error)")
        }
        
        // Clear HTTPCookieStorage (if applicable)
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        
        loggedOut()
    }
}

// MARK: - Base64ImageView

struct Base64ImageView: View {
    let base64String: String
    
    var body: some View {
        if let image = decodeBase64ToImage(base64String) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 50, maxHeight: 50)
        } else {
            Text("Invalid image data")
                .foregroundColor(.red)
        }
    }
    
    // Function to decode Base64 string to UIImage
    private func decodeBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}

// MARK: - Child Profile View

struct ChildProfileView: View {
    var child: Person
    @Binding var children: [Person]
    
    @State private var disabilities: String = ""
    @State private var pics: Int = 0
    
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    
    @State private var showingAddDisability = false
    
    struct Disability: Identifiable, Hashable {
        let id: UUID = UUID()
        let name: String
    }
    
    @State private var alertMessage: String?
    
    @State private var alertIsPresented: Bool = false
    
    // Computed property to split the disabilities into a list
    private var disabilityList: [Disability] {
        disabilities.split(separator: ";").map { Disability(name: String($0)) }
    }
    
    var body: some View {
        List {
            // Display basic details about the child
            HStack {
                Text("First Name:")
                Spacer()
                Text(child.FIRSTNAME)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Last Name:")
                Spacer()
                Text(child.LASTNAME)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Email:")
                Spacer()
                Text(child.EMAIL)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Phone:")
                Spacer()
                Text(child.PHONE)
                    .foregroundColor(.gray)
            }
            
            if let birthYear = child.BIRTH_YEAR {
                HStack {
                    Text("Birth Year:")
                    Spacer()
                    Text(birthYear)
                        .foregroundColor(.gray)
                }
            }
            
            if let grade = child.GRADE {
                HStack {
                    Text("Grade:")
                    Spacer()
                    Text(grade)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("Gender:")
                Spacer()
                Text(child.GENDER.capitalized)
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Disabilities")) {
                if disabilityList.isEmpty {
                    Text("No disabilities listed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(disabilityList, id: \.self) { disability in
                        Label(
                            disability.name,
                            systemImage: arrayOfDisabilitiesPerChild.randomElement()!
                        )
                    }.onDelete(perform: {
                        guard let index = $0.first else { return }
                        deleteDisability(disabilityList[index])
                    })
                }
            }
            
            
            VStack(alignment: .leading) {
                Text("Allow to take picture of my child:")
                    .font(.headline)
                Toggle(isOn: Binding(
                    get: { pics == 1 },
                    set: { newValue in
                        pics = newValue ? 1 : 0
                    }
                )) {
                    Text(pics == 1 ? "Yes" : "No")
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
            
            // Save Button (If you want to implement saving the data)
            Button(action: {
                // Handle save action
                updateChild()
            }) {
                Text("Save Changes")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            disabilities = child.DISABILITIES
            pics = child.PICS
        }
        .navigationTitle("Child profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddDisability.toggle()
                }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }.navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                fetchAllChildren()
                self.mode.wrappedValue.dismiss()
            }) {
                Label("Back", systemImage: "chevron.backward").labelStyle(TitleAndIconLabelStyle())
            })
            .sheet(isPresented: $showingAddDisability) {
                AddDisabilityView(disabilityList: $disabilities, showingAddDisability: $showingAddDisability)
            }
            .alert(isPresented: $alertIsPresented) {
                Alert(title: Text("Athlead"), message: Text(alertMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
    }
    func updateChild(){
        let childUpdate = ChildUpdate(disabilities: disabilities, pics: pics)
        
        fetch("parents/children/\(child.ID)", ChildUpdateResponse.self, "PATCH", nil, childUpdate) { result in
            switch result {
            case .success( _):
                alertMessage = "Child updated successfully"
                alertIsPresented.toggle()
            case .failure(let err):
                alertMessage = "Failed to update child: \(err)"
                alertIsPresented.toggle()
            }
        }
        
        
    }
    
    func deleteDisability(_ disability: Disability) {
        if !child.DISABILITIES.contains(disability.name) {
            print ("Disability not found in main list, thus not saved yet")
            return
        }
        
        
        let disabilityListCopy = disabilityList.filter { $0.name != disability.name }
        
        let disabilityListCopyString = disabilityListCopy.map { $0.name }.joined(separator: ";")
        
        
        let childUpdate = ChildUpdate(disabilities: disabilityListCopyString, pics: nil)
        
        fetch("parents/children/\(child.ID)", ChildUpdateResponse.self, "PATCH", nil, childUpdate) { result in
            switch result {
            case .success( _):
                print("Child updated successfully")
            case .failure(let err):
                print("Failed to update child: \(err)")
            }
        }
    }
    func fetchAllChildren() {
        fetch("parents/children", ParentsChildrenResponse.self){ result in
            switch result {
            case .success(let resp):
                children = resp.data
                
            case .failure(let err): print(err)
            }
        }
    }
}



struct AddDisabilityView: View {
    @Binding var disabilityList: String
    @State private var newDisability: String = ""
    @Binding var showingAddDisability: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: arrayOfDisabilitiesPerChild.randomElement()!)
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(.leading, 20)
                    
                    TextField("Enter disability", text: $newDisability)
                        .padding()
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                Button(action: {
                    // Check if the new disability is not empty
                    if !newDisability.isEmpty {
                        // Append the new disability to the list
                        if disabilityList.isEmpty {
                            disabilityList = newDisability
                        } else {
                            disabilityList += ";\(newDisability)"
                        }
                        // Clear the text field
                        newDisability = ""
                        showingAddDisability.toggle()
                        
                    }
                }) {
                    HStack {
                        Text("Add Disability")
                            .fontWeight(.semibold)
                            .padding()
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitle("Add Disability", displayMode: .inline)
        }
    }
}
