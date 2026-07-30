import Foundation

/// Talks to IBM watsonx Assistant (v2 API) using plain REST calls, so no
/// extra SDK dependency is required. You need:
///   1. A watsonx Assistant instance on IBM Cloud (Plus plan or higher for v2).
///   2. Your instance's Service URL (e.g. https://api.<region>.assistant.watson.cloud.ibm.com)
///   3. Your Assistant ID (from Assistant settings -> API details)
///   4. An IAM API key (from IBM Cloud -> Manage -> Access (IAM) -> API keys)
/// Fill these into WatsonConfig below. Never commit real keys to source
/// control — for a shipped app, fetch the key from your own backend instead
/// of embedding it in the client.
enum WatsonConfig {
    static let serviceURL = "https://api.REGION.assistant.watson.cloud.ibm.com/instances/YOUR_INSTANCE_ID"
    static let assistantId = "YOUR_ASSISTANT_ID"
    static let apiKey = "YOUR_IAM_API_KEY"
    static let apiVersion = "2021-06-14"
}

class WatsonChatService {
    static let shared = WatsonChatService()
    private init() {}

    private var sessionId: String?
    private var iamToken: String?
    private var tokenExpiry: Date = .distantPast

    enum WatsonError: Error, LocalizedError {
        case notConfigured
        case network(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Watson isn't configured yet — add your instance details in WatsonConfig."
            case .network(let msg): return msg
            }
        }
    }

    private func ensureIAMToken() async throws -> String {
        if let token = iamToken, Date() < tokenExpiry {
            return token
        }
        guard WatsonConfig.apiKey != "YOUR_IAM_API_KEY" else {
            throw WatsonError.notConfigured
        }

        var request = URLRequest(url: URL(string: "https://iam.cloud.ibm.com/identity/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=\(WatsonConfig.apiKey)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(IAMTokenResponse.self, from: data)
        iamToken = decoded.accessToken
        tokenExpiry = Date().addingTimeInterval(Double(decoded.expiresIn - 60))
        return decoded.accessToken
    }

    private func ensureSession() async throws -> String {
        if let sessionId { return sessionId }
        let token = try await ensureIAMToken()

        let url = URL(string: "\(WatsonConfig.serviceURL)/v2/assistants/\(WatsonConfig.assistantId)/sessions?version=\(WatsonConfig.apiVersion)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(SessionResponse.self, from: data)
        sessionId = decoded.sessionId
        return decoded.sessionId
    }

    /// Sends a user message and returns the assistant's combined reply text.
    func sendMessage(_ text: String) async throws -> String {
        let token = try await ensureIAMToken()
        let session = try await ensureSession()

        let url = URL(string: "\(WatsonConfig.serviceURL)/v2/assistants/\(WatsonConfig.assistantId)/sessions/\(session)/message?version=\(WatsonConfig.apiVersion)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = MessageRequest(input: MessageInput(messageType: "text", text: text))
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(MessageResponse.self, from: data)

        let combined = decoded.output.generic?
            .compactMap { $0.text }
            .joined(separator: "\n") ?? "Sorry, I didn't get a response."
        return combined
    }
}

// MARK: - Wire models

private struct IAMTokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

private struct SessionResponse: Decodable {
    let sessionId: String
    enum CodingKeys: String, CodingKey { case sessionId = "session_id" }
}

private struct MessageInput: Encodable {
    let messageType: String
    let text: String
    enum CodingKeys: String, CodingKey {
        case messageType = "message_type"
        case text
    }
}

private struct MessageRequest: Encodable {
    let input: MessageInput
}

private struct MessageResponse: Decodable {
    let output: Output
    struct Output: Decodable {
        let generic: [GenericItem]?
    }
    struct GenericItem: Decodable {
        let text: String?
    }
}
