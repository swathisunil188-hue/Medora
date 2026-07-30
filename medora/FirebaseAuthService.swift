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
// Fallback stub when Firebase isn't linked
class FirebaseAuthService {
    static let shared = FirebaseAuthService()
    private init() {}

    enum AuthError: Error, LocalizedError {
        case notConfigured
        var errorDescription: String? {
            "Firebase is not configured. Add the Firebase SDKs or remove Firebase usage."
        }
    }

    var isSignedIn: Bool { false }

    func register(user: User, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        completion(.failure(AuthError.notConfigured))
    }

    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        completion(.failure(AuthError.notConfigured))
    }

    func logout() throws { /* no-op */ }

    func updateProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AuthError.notConfigured))
    }

    func saveReport(_ report: Report, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AuthError.notConfigured))
    }
}
#endif
