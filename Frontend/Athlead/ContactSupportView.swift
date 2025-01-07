//
//  ContactSupportView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 07.01.25.
//


import SwiftUI

struct ContactSupportView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitted: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Title
                Text("Contact Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Introduction text
                Text("If you have any questions or issues, please fill out the form below and we will get back to you as soon as possible.")
                    .font(.body)
                    .padding(.bottom)
                
                // Name Field
                Text("Name")
                    .font(.title2)
                    .fontWeight(.semibold)
                TextField("Enter your name", text: $name)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.bottom)
                
                // Email Field
                Text("Email")
                    .font(.title2)
                    .fontWeight(.semibold)
                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.bottom)
                
                // Message Field
                Text("Message")
                    .font(.title2)
                    .fontWeight(.semibold)
                TextEditor(text: $message)
                    .frame(height: 150)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                    .padding(.bottom)
                
                // Submit Button
                Button(action: submitForm) {
                    Text("Submit")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top)
                
                // Confirmation Alert
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(isSubmitted ? "Thank You!" : "Error"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding()
        }
        .navigationBarTitle("Contact Support", displayMode: .inline)
    }
    
    private func submitForm() {
        if name.isEmpty || email.isEmpty || message.isEmpty {
            alertMessage = "Please fill out all fields before submitting."
            showAlert = true
            return
        }
        
        // You can replace this with actual form submission logic (API call, email, etc.)
        isSubmitted = true
        alertMessage = "Your message has been submitted. We will get back to you soon!"
        showAlert = true
        
        // Clear fields after submission
        name = ""
        email = ""
        message = ""
    }
}
