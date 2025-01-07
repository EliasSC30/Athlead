//
//  YourProfileView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//
import SwiftUI


struct YourProfileView: View {
    let loggedOut: () -> Void
    @State private var isLoading = false
    @State private var children: [Person] = []
    @State private var profilePicture: String = ""
    
    var body: some View {
        if isLoading {
            ProgressView("Lade Profil...")
        } else {
            NavigationView {
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
                                Text("Nathanäl Hendrik Özcan-Wichmann")
                                    .font(.headline)
                                Text("Igelgruppe")
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
                    
                    if children.isEmpty {
                        Section(header: Text("Meine Kinder")) {
                            NavigationLink(destination: ParentView(children: $children)){
                                Label("Meine Kinder", systemImage: "person")
                            }
                        }
                    }
                    
                    // Settings Section
                    Section(header: Text("Settings")) {
                        NavigationLink(destination: UploadPhotoView(onPicChanged: {(pic: String) -> Void in profilePicture = pic})){
                            Label("Edit Profile Picture", systemImage: "pencil")
                        }
                        NavigationLink(destination: Text("Notification Preferences")) {
                            Label("Notifications", systemImage: "bell")
                        }
                        NavigationLink(destination: Text("Privacy Settings")) {
                            Label("Privacy", systemImage: "lock")
                        }
                    }
                    
                    // More Info Section
                    Section(header: Text("More")) {
                        NavigationLink(destination: Text("Event Schedule")) {
                            Label("Event Schedule", systemImage: "calendar")
                        }
                        NavigationLink(destination: Text("Contact Support")) {
                            Label("Contact Support", systemImage: "envelope")
                        }
                        NavigationLink(destination: Text("About the App")) {
                            Label("About", systemImage: "info.circle")
                        }
                    }
                }
                .navigationTitle("Sportfest Overview")
                .listStyle(InsetGroupedListStyle())
            }.onAppear{
                isLoading = true
                fetch("parents/children", ParentsChildrenResponse.self){ result in
                    switch result {
                    case .success(let resp): children = resp.children
                    case .failure(let err): print(err);
                    }
                }
                
                if User != nil {
                    fetch("photos/"+User.unsafelyUnwrapped.ID, Photo.self){ result in
                        switch result{
                        case .success(let photo): profilePicture = photo.data
                        case .failure(let _): print("Could not get profile picture")
                        }
                    }
                }
                isLoading = false
                
            }
        }
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


import SwiftUI

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

