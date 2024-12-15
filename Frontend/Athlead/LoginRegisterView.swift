//
//  LoginRegisterView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//

import SwiftUI

let apiUrl = "http://localhost:8000"

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
    
    func authenticateUser()
    {
        if (isLoginMode){
            if loginWithToken() {
                return;
            }
            loginWithPassword()
        } else {
            register()
        }
    }
    
    func loginWithPassword()
    {
        
    }

    func loginWithToken() -> Bool {
        if SessionToken == nil { return false; }
        
        let url = URL(string: "\(apiURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let tokenLoginData = LoginData(email: email,
                                       password: nil,
                                       token: SessionToken)
        
        
        guard let encode = try? JSONEncoder().encode(tokenLoginData) else {
            print("Failed to encode loginData")
            return false;
        }
        
        request.httpBody = encode
        
        var loginWasSuccessfull = false;
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error trying to login: \(error)")
                return
            }
            
            guard let data = data, let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                print("Failed to decode loginResponse")
                return
            }
            
            SessionToken = loginResponse.data;
            UserId = loginResponse.id;
            loginWasSuccessfull = true;
            isLoggedIn = true;
            
        }.resume()
        
        if !loginWasSuccessfull {
            SessionToken = nil;
            UserId = nil;
            isLoggedIn = false;
        }
        
        
        return loginWasSuccessfull;
    }
    
    func register() {
        let url = URL(string: "\(apiURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let registryData = RegisterData(email: email,
                                        password: password,
                                        
                                        // TODO
                                        first_name: "Elias",
                                        last_name: "Jo",
                                        phone: "123456789",
                                        grade: "4",
                                        birth_year: "1999",
                                        role: "Admin"
        )
        
        
        guard let encode = try? JSONEncoder().encode(registryData) else {
            print("Failed to encode registryData")
            return;
        }
        
        print("email: ", email, "password", password)
        print(encode)
        
        request.httpBody = encode
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error trying to register: \(error)")
                return
            }
            
            guard let data = data, let registerResponse = try? JSONDecoder().decode(RegisterResponse.self, from: data) else {
                print("Failed to decode registerResponse")
                return
            }
            
            print(data)
            print(registerResponse)
            SessionToken = registerResponse.data
            
        }.resume()
        
    }
}
