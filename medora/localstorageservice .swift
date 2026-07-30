//import Foundation
import CryptoKit

class LocalStorageService {
    static let shared = LocalStorageService()
    private init() {}

    private let usersKey = "app_users"
    private let currentUserKey = "current_user"

    func saveUser(_ user: User) {
        var users = loadUsers()
        users.append(user)
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    func loadUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }

    func findUser(email: String, passwordHash: String) -> User? {
        loadUsers().first { $0.email.lowercased() == email.lowercased() && $0.passwordHash == passwordHash }
    }

    func emailExists(_ email: String) -> Bool {
        loadUsers().contains { $0.email.lowercased() == email.lowercased() }
    }

    func setCurrentUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserKey)
        }
    }

    func getCurrentUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
}

func hashPassword(_ password: String) -> String {
    let inputData = Data(password.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
//  localstorage .swift
//  medora
//
//  Created by STUDENT_24 on 30/07/26.
//

