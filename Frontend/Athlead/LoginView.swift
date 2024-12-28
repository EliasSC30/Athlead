//
//  LoginView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 18.12.24.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showForgotPassword = false  // State to navigate to ForgotPasswordView
    @State private var loginError: String = ""  // State to store login error message

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // App Title
                VStack(spacing: 8) {
                    Text("Athlead")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Please log in to your account")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                // Email TextField
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    TextField("Enter your email", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                // Password SecureField
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $showForgotPassword) {
                            ForgotPasswordView()
                        }
                    }
                }

                // Login Button
                Button(action: {
                    Task {
                        await authenticateUser()
                    }
                }) {
                    Text("Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(
                            color: Color.blue.opacity(0.3), radius: 10, x: 0,
                            y: 5)
                }
                .padding(.top, 20)

                // Display Login Error
                if !loginError.isEmpty {
                    Text(loginError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
            }
            .padding(20)
            .frame(maxWidth: 400)
            
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func authenticateUser() async {
        print("Authenticating user with email: \(email) and password: \(password)")

        let url = URL(string: "\(apiURL)/login")!

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let loginData = LoginData(email: email, password: password, token: nil)
        guard let encodedData = try? JSONEncoder().encode(loginData) else {
            loginError = "Failed to prepare login request. Please try again."
            return
        }
        request.httpBody = encodedData
        
        do {
            // Perform the request asynchronously
            let result = try await executeURLRequestAsync(request: request)
            
            switch result {
            case .success(_, let data):
                if let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                    if loginResponse.status == "success" {
                        DispatchQueue.main.async {
                            self.isLoggedIn = true
                            self.loginError = ""
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.loginError = "Incorrect email or password. Please try again."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.loginError = "Invalid server response. Please contact support."
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loginError = "Network error: \(error.localizedDescription). Please try again."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.loginError = "Unexpected error: \(error.localizedDescription). Please try again."
            }
        }
    }


}
struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode  // For dismissing the sheet
    @State private var email: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Forgot Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Enter your email to reset your password")
                    .foregroundColor(.gray)
                    .font(.subheadline)

                TextField("Email", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                Button(action: {
                    sendPasswordReset()
                }) {
                    Text("Send Reset Link")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(
                            color: Color.blue.opacity(0.3), radius: 10, x: 0,
                            y: 5)
                }

                Spacer()
            }
            .padding(20)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }

    private func sendPasswordReset() {
        // Add logic to send the password reset email
        print("Password reset link sent to: \(email)")
    }
}
