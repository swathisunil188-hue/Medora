//import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToLogin = false

    let genders = ["Male", "Female", "Other"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Account").font(.title).fontWeight(.bold).padding(.top, 30)

                CustomTextField(title: "Name", text: $name)
                CustomTextField(title: "Age", text: $age, keyboardType: .numberPad)

                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                CustomTextField(title: "Phone", text: $phone, keyboardType: .phonePad)
                CustomTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                CustomTextField(title: "Password", text: $password, isSecure: true)
                CustomTextField(title: "Confirm Password", text: $confirmPassword, isSecure: true)

                if showError {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: "Create Account", action: handleRegister)
                    .padding(.top, 8)
            }
            .padding(.horizontal)
        }
        .navigationDestination(isPresented: $navigateToLogin) { LoginView() }
    }

    private func handleRegister() {
        showError = false
        guard !name.isEmpty, let ageInt = Int(age), ageInt > 0,
              !phone.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields correctly."
            showError = true
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            showError = true
            return
        }
        guard !LocalStorageService.shared.emailExists(email) else {
            errorMessage = "An account with this email already exists."
            showError = true
            return
        }

        let newUser = User(
            name: name, age: ageInt, gender: gender, phone: phone,
            email: email, passwordHash: hashPassword(password)
        )
        LocalStorageService.shared.saveUser(newUser)
        navigateToLogin = true
    }
}
//  registerview.swift
//  medora
//
//  Created by STUDENT_24 on 30/07/26.
//

