//
//  LoginView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 18.12.24.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State var loginAttemptHappened: () -> Void
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showForgotPassword = false  // State to navigate to ForgotPasswordView
    @State private var loginError: String = ""  // State to store login error message
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if isLoading {
                Text("Logging in..")
            }
            else {
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
                            isLoading = true;
                            await authenticateUser()
                            loginAttemptHappened()
                            isLoading = false;
                            
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
        }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func authenticateUser() async {
        isLoading = true
        loginError = ""
        
        let loginData = LoginData(email: email, password: password, token: nil)
        
        fetch("login", LoginResponse.self, "POST", nil, loginData) { result in
            switch result {
            case .success(let loginResponse):
                if loginResponse.status == "success" {
                    User = loginResponse.user
                    loginAttemptHappened()
                } else {
                    loginError = "Incorrect email or password. Please try again."
                }
                isLoading = false
            case .failure( _):
                loginError = "Incorrect email or password. Please try again."
                isLoading = false
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
