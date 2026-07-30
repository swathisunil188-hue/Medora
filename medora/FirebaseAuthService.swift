import Foundation
// Add via Xcode: File -> Add Package Dependencies -> https://github.com/firebase/firebase-ios-sdk
// Select products: FirebaseAuth, FirebaseFirestore
// Also drag your GoogleService-Info.plist (from the Firebase console) into the project root.
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
import FirebaseAuth
import FirebaseFirestore
#else
// Lightweight stubs so the project builds without Firebase packages present.
// The service below will return a helpful error at runtime.
#endif

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
/// Replaces the local-only auth from Phase 1 with real Firebase Authentication,
/// and mirrors the user's profile into Firestore so it's available across devices.
/// LocalStorageService is still used as an on-device cache of "who is currently
/// signed in" so the splash screen can route instantly without waiting on network.
class FirebaseAuthService {
    static let shared = FirebaseAuthService()
    private init() {}

    private var db: Firestore { Firestore.firestore() }

    enum AuthError: Error, LocalizedError {
        case notSignedIn
        case profileMissing
        case underlying(String)

        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You're not signed in."
            case .profileMissing: return "Couldn't find your profile."
            case .underlying(let msg): return msg
            }
        }
    }

    var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }

    func register(user: User, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: user.email, password: password) { result, error in
            if let error = error {
                completion(.failure(AuthError.underlying(error.localizedDescription)))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(AuthError.underlying("No user ID returned.")))
                return
            }

            var savedUser = user
            savedUser.id = UUID(uuidString: uid) ?? UUID()

            do {
                try self.db.collection("users").document(uid).setData(from: savedUser)
                LocalStorageService.shared.setCurrentUser(savedUser)
                completion(.success(savedUser))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(AuthError.underlying(error.localizedDescription)))
                return
            }
            guard let uid = result?.user.uid else {
                completion(.failure(AuthError.underlying("No user ID returned.")))
                return
            }

            self.db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let snapshot = snapshot, snapshot.exists,
                      let user = try? snapshot.data(as: User.self) else {
                    completion(.failure(AuthError.profileMissing))
                    return
                }
                LocalStorageService.shared.setCurrentUser(user)
                completion(.success(user))
            }
        }
    }

    func logout() throws {
        try Auth.auth().signOut()
        LocalStorageService.shared.logout()
    }

    /// Push local edits (allergies, conditions, emergency contact, etc.) back to Firestore.
    func updateProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(AuthError.notSignedIn))
            return
        }
        do {
            try db.collection("users").document(uid).setData(from: user, merge: true)
            LocalStorageService.shared.setCurrentUser(user)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    /// Syncs a saved Report up to Firestore under the current user, so reports
    /// generated in Phase 6 are backed up across devices.
    func saveReport(_ report: Report, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(AuthError.notSignedIn))
            return
        }
        do {
            try db.collection("users").document(uid)
                .collection("reports").document(report.id.uuidString)
                .setData(from: report)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
#else
// Local-only fallback when Firebase isn't linked. This keeps the app functional
// without cloud services. DO NOT use this for production auth.
class FirebaseAuthService {
    static let shared = FirebaseAuthService()
    private init() {}

    // Keys for UserDefaults storage
    private let currentEmailKey = "auth.currentEmail"
    private let usersKey = "auth.users"           // [String: Data] mapping email -> encoded User
    private let passwordsKey = "auth.passwords"   // [String: String] mapping email -> password (demo only)
    private let reportsKeyPrefix = "auth.reports." // prefix + email -> [Data] encoded Report

    enum AuthError: Error, LocalizedError {
        case notSignedIn
        case userNotFound
        case wrongPassword
        case emailInUse
        case notConfigured
        case decodeFailed

        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "You're not signed in."
            case .userNotFound: return "We couldn't find an account for that email."
            case .wrongPassword: return "The password you entered is incorrect."
            case .emailInUse: return "An account already exists for that email."
            case .notConfigured: return "Using local-only auth fallback. Add Firebase to enable cloud sync."
            case .decodeFailed: return "Failed to read saved data."
            }
        }
    }

    var isSignedIn: Bool {
        UserDefaults.standard.string(forKey: currentEmailKey) != nil
    }

    private func loadUsers() -> [String: Data] {
        (UserDefaults.standard.dictionary(forKey: usersKey) as? [String: Data]) ?? [:]
    }

    private func saveUsers(_ dict: [String: Data]) {
        UserDefaults.standard.set(dict, forKey: usersKey)
    }

    private func loadPasswords() -> [String: String] {
        (UserDefaults.standard.dictionary(forKey: passwordsKey) as? [String: String]) ?? [:]
    }

    private func savePasswords(_ dict: [String: String]) {
        UserDefaults.standard.set(dict, forKey: passwordsKey)
    }

    private func setCurrentEmail(_ email: String?) {
        UserDefaults.standard.set(email, forKey: currentEmailKey)
    }

    private func currentEmail() -> String? {
        UserDefaults.standard.string(forKey: currentEmailKey)
    }

    private func reportsKey(for email: String) -> String { reportsKeyPrefix + email }

    private func loadReports(for email: String) -> [Data] {
        (UserDefaults.standard.array(forKey: reportsKey(for: email)) as? [Data]) ?? []
    }

    private func saveReports(_ data: [Data], for email: String) {
        UserDefaults.standard.set(data, forKey: reportsKey(for: email))
    }

    func register(user: User, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().async {
            var users = self.loadUsers()
            var passwords = self.loadPasswords()
            let email = user.email.lowercased()

            if users[email] != nil {
                completion(.failure(AuthError.emailInUse))
                return
            }

            var newUser = user
            // Ensure we have an ID for local storage
            if newUser.id == UUID(uuidString: email) { /* unlikely */ } else {
                // Stable-ish UUID based on email for demo, or generate new
                newUser.id = UUID()
            }

            do {
                let encoded = try JSONEncoder().encode(newUser)
                users[email] = encoded
                passwords[email] = password
                self.saveUsers(users)
                self.savePasswords(passwords)
                LocalStorageService.shared.setCurrentUser(newUser)
                self.setCurrentEmail(email)
                completion(.success(newUser))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().async {
            let key = email.lowercased()
            let users = self.loadUsers()
            let passwords = self.loadPasswords()

            guard let data = users[key] else {
                completion(.failure(AuthError.userNotFound))
                return
            }
            guard passwords[key] == password else {
                completion(.failure(AuthError.wrongPassword))
                return
            }
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                LocalStorageService.shared.setCurrentUser(user)
                self.setCurrentEmail(key)
                completion(.success(user))
            } catch {
                completion(.failure(AuthError.decodeFailed))
            }
        }
    }

    func logout() throws {
        setCurrentEmail(nil)
        LocalStorageService.shared.logout()
    }

    func updateProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global().async {
            var users = self.loadUsers()
            let email = user.email.lowercased()
            do {
                let encoded = try JSONEncoder().encode(user)
                users[email] = encoded
                self.saveUsers(users)
                LocalStorageService.shared.setCurrentUser(user)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func saveReport(_ report: Report, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global().async {
            guard let email = self.currentEmail() else {
                completion(.failure(AuthError.notSignedIn))
                return
            }
            var data = self.loadReports(for: email)
            do {
                let encoded = try JSONEncoder().encode(report)
                data.append(encoded)
                self.saveReports(data, for: email)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
#endif
