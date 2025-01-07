//
//  YourProfileView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 02.12.24.
//
import SwiftUI

let example = "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";

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
                        case .failure(let err): print("Could not get profile picture")
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

