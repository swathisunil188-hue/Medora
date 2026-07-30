import SwiftUI
import Foundation

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToHome = false
    @State private var navigateToRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .resizable().scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        Text("Welcome Back").font(.title).fontWeight(.bold)
                        Text("Sign in to continue").font(.subheadline).foregroundColor(.gray)
                    }
                    .padding(.top, 60)

                    VStack(spacing: 16) {
                        CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                        CustomTextField(title: "Password", text: $password, isSecure: true)

                        if showError {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)

                    PrimaryButton(title: "Log In", action: handleLogin)
                        .padding(.horizontal)

                    Spacer()

                    HStack {
                        Text("Don't have an account?").foregroundColor(.gray)
                        Button("Sign Up") { navigateToRegister = true }
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToHome) { HomeDashboardView() }
            .navigationDestination(isPresented: $navigateToRegister) { RegisterView() }
        }
    }

    private func handleLogin() {
        showError = false
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            errorMessage = "Please enter both email and password."
            showError = true
            return
        }
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            showError = true
            return
        }

        let hashed = hashPassword(trimmedPassword)
        if let user = LocalStorageService.shared.findUser(email: trimmedEmail, passwordHash: hashed) {
            LocalStorageService.shared.setCurrentUser(user)
            navigateToHome = true
        } else {
            errorMessage = "Invalid email or password."
            showError = true
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
//  loginview.swift
//  medora
//
//  Created by STUDENT_24 on 30/07/26.
//


