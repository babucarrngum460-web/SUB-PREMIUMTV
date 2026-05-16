import Foundation
import SwiftUI

// MARK: - User Model

struct UserAccount: Identifiable, Codable, Equatable {

    let id: UUID

    var name: String
    var username: String
    var bio: String

    var email: String
    var password: String

    var avatarPath: String?

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        username: String,
        bio: String = "",
        email: String,
        password: String,
        avatarPath: String? = nil,
        createdAt: Date = Date()
    ) {

        self.id = id
        self.name = name
        self.username = username
        self.bio = bio
        self.email = email
        self.password = password
        self.avatarPath = avatarPath
        self.createdAt = createdAt
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {

    case message(String)

    var errorDescription: String? {

        switch self {

        case .message(let text):
            return text
        }
    }
}

// MARK: - Auth Manager

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    @Published var users: [UserAccount] = [] {
        didSet {
            saveUsers()
        }
    }

    @Published var currentUser: UserAccount? {
        didSet {
            saveCurrentUser()
        }
    }

    @Published var isLoggedIn = false

    private let usersKey = "subpremium_tv_users"
    private let currentUserKey = "subpremium_tv_current_user"

    private init() {

        loadUsers()
        restoreSession()
    }

    // MARK: - Register

    func register(
        name: String,
        username: String,
        bio: String,
        email: String,
        password: String
    ) -> Result<UserAccount, AuthError> {

        let cleanName =
        name.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanUsername =
        normalizedUsername(username)

        let cleanEmail =
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !cleanName.isEmpty else {

            return .failure(
                .message("Please enter your name.")
            )
        }

        guard cleanEmail.contains("@"),
              cleanEmail.contains(".") else {

            return .failure(
                .message("Please enter a valid email.")
            )
        }

        guard password.count >= 6 else {

            return .failure(
                .message("Password must be at least 6 characters.")
            )
        }

        guard isValidUsername(cleanUsername) else {

            return .failure(
                .message(
                    "Username must be 5–20 characters with lowercase letters, numbers, or underscore."
                )
            )
        }

        guard !isEmailTaken(cleanEmail) else {

            return .failure(
                .message("This email already exists.")
            )
        }

        guard !isUsernameTaken(cleanUsername) else {

            return .failure(
                .message("This username already exists.")
            )
        }

        let user =
        UserAccount(
            name: cleanName,
            username: cleanUsername,
            bio: bio,
            email: cleanEmail,
            password: password
        )

        users.insert(user, at: 0)

        currentUser = user
        isLoggedIn = true

        return .success(user)
    }

    // MARK: - Login

    func login(
        email: String,
        password: String
    ) -> Result<UserAccount, AuthError> {

        let cleanEmail =
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let user =
                users.first(where: {
                    $0.email == cleanEmail
                }) else {

            return .failure(
                .message("Account not found.")
            )
        }

        guard user.password == password else {

            return .failure(
                .message("Incorrect password.")
            )
        }

        currentUser = user
        isLoggedIn = true

        return .success(user)
    }

    // MARK: - Logout

    func logout() {

        currentUser = nil
        isLoggedIn = false
    }

    // MARK: - Update Profile

    func updateProfile(
        name: String,
        username: String,
        bio: String,
        avatarPath: String?
    ) -> Result<UserAccount, AuthError> {

        guard var current = currentUser else {

            return .failure(
                .message("No logged-in user.")
            )
        }

        let cleanName =
        name.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanUsername =
        normalizedUsername(username)

        guard !cleanName.isEmpty else {

            return .failure(
                .message("Please enter your name.")
            )
        }

        guard isValidUsername(cleanUsername) else {

            return .failure(
                .message("Invalid username.")
            )
        }

        if cleanUsername != current.username {

            guard !isUsernameTaken(cleanUsername) else {

                return .failure(
                    .message("Username already exists.")
                )
            }
        }

        current.name = cleanName
        current.username = cleanUsername
        current.bio = bio
        current.avatarPath = avatarPath

        if let index =
            users.firstIndex(where: {
                $0.id == current.id
            }) {

            users[index] = current
        }

        currentUser = current

        return .success(current)
    }

    // MARK: - Validation

    func normalizedUsername(
        _ value: String
    ) -> String {

        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    func isValidUsername(
        _ username: String
    ) -> Bool {

        let clean =
        normalizedUsername(username)

        return clean.range(
            of: "^[a-z0-9_]{5,20}$",
            options: .regularExpression
        ) != nil
    }

    func isEmailTaken(
        _ email: String
    ) -> Bool {

        users.contains {
            $0.email.lowercased() ==
            email.lowercased()
        }
    }

    func isUsernameTaken(
        _ username: String
    ) -> Bool {

        users.contains {
            $0.username.lowercased() ==
            username.lowercased()
        }
    }

    // MARK: - Persistence

    private func saveUsers() {

        guard let data =
                try? JSONEncoder().encode(users) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: usersKey
        )
    }

    private func loadUsers() {

        guard let data =
                UserDefaults.standard.data(
                    forKey: usersKey
                ),
              let decoded =
                try? JSONDecoder().decode(
                    [UserAccount].self,
                    from: data
                ) else {

            users = []
            return
        }

        users = decoded
    }

    private func saveCurrentUser() {

        guard let currentUser else {

            UserDefaults.standard.removeObject(
                forKey: currentUserKey
            )

            return
        }

        guard let data =
                try? JSONEncoder().encode(currentUser) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: currentUserKey
        )
    }

    private func restoreSession() {

        guard let data =
                UserDefaults.standard.data(
                    forKey: currentUserKey
                ),
              let decoded =
                try? JSONDecoder().decode(
                    UserAccount.self,
                    from: data
                ) else {

            currentUser = nil
            isLoggedIn = false

            return
        }

        currentUser = decoded
        isLoggedIn = true
    }
}
