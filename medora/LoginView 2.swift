import SwiftUI

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isLoading = false
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
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email").font(.footnote).foregroundColor(.secondary)
                            TextField("you@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password").font(.footnote).foregroundColor(.secondary)
                            SecureField("••••••••", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }

                        if showError {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)

                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoading ? "Logging In…" : "Log In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.blue.opacity(0.6) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
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

        isLoading = true

        // Phase 5: authenticate against Firebase instead of local UserDefaults.
        FirebaseAuthService.shared.login(email: trimmedEmail, password: trimmedPassword) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    navigateToHome = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
