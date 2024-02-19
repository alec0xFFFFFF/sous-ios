//
//  LoginView.swift
//  sous
//
//  Created by Alexander K White on 11/25/23.
//
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct LoginSignupView: View {
    @State private var showingGoogleLogin = false

    var body: some View {
        VStack {
            GoogleSignInButton(action: { self.showingGoogleLogin = true })
            .sheet(isPresented: $showingGoogleLogin) {
                // Google Sign-In View
            }
            .frame(height: 44)
            .padding(.horizontal)

            SignInWithAppleButton(.signIn) { request in
                // Apple Sign-In Request Configuration
            } onCompletion: { result in
                // Handle Apple Sign-In
            }
            .frame(height: 44)
            .padding(.horizontal)
            // Style the button
        }
    }
    
//    func handleGoogleSignInButton() {
//      GIDSignIn.sharedInstance.signIn(
//        withPresenting: rootViewController) { signInResult, error in
//          guard let result = signInResult else {
//            // Inspect error
//            return
//          }
//          // If sign in succeeded, display the app's main content View.
//            
//            
//        }
//      )
//    }
}


struct LoginSignupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignupView()
    }
}
