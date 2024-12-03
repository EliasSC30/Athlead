//
//  LoginRegisterView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI

struct LoginRegisterView: View {
    @Binding var isLoggedIn: Bool // Binding zum Ändern des Auth-Status
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isLoginMode ? "Login" : "Register")
                .font(.largeTitle)
                .bold()

            Picker("", selection: $isLoginMode) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                authenticateUser()
            }) {
                Text(isLoginMode ? "Login" : "Register")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top)

            Spacer()
        }
        .padding()
    }

    func authenticateUser() {

    }
}
