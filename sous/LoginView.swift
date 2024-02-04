//
//  LoginView.swift
//  sous
//
//  Created by Alexander K White on 11/25/23.
//

import SwiftUI
import Foundation

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @AppStorage("jwt") private var jwt: String?
    @State private var isShowingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Image("duck") // Placeholder image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 20)
                
                Button(action: login) {
                    Text("Log In")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
              
                Button(action: {
                    // Reset password
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Button(action: {
                    // Register as a user
                }) {
                    Text("Register")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(6)
                }
                .padding(.top, 20)
            }
            .padding()
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
  
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
           alertMessage = "Please enter both email and password."
            isShowingAlert = true
            return
        }
        
        let loginURL = URL(string: "https://app.com/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = bodyParameters
            .map { key, value in
                return "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
            .joined(separator: "&")
            .data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = error.localizedDescription
                    isShowingAlert = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid response from server."
                    isShowingAlert = true
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let receivedJWT = json["jwt"] as? String {
                    DispatchQueue.main.async {
                        jwt = receivedJWT
                    }
                } else {
                    DispatchQueue.main.async {
                        alertMessage = "Invalid JSON response from server."
                        isShowingAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = "JSON parsing error: \(error.localizedDescription)"
                    isShowingAlert = true
                }
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
