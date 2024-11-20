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
        // Simulierte Anfrage an Backend
        guard let url = URL(string: "http://localhost:8080/isLoggedIn") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let credentials = ["email": email, "password": password]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
        } catch {
            print("Invalid JSON")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let response = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.isLoggedIn = response.isLoggedIn
                }
            } else {
                print("Invalid response")
            }
        }.resume()
    }
}

struct LoginResponse: Codable {
    let isLoggedIn: Bool
}
