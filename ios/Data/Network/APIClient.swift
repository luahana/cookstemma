import Foundation

// MARK: - API Configuration

enum APIConfiguration {
    // API URLs per environment (configured via build configurations in project.yml)
    // DEV builds use dev server, PROD builds use production server
    #if DEV
    // For local development, uncomment and use your Mac's IP:
    // static let baseURL = URL(string: "http://192.168.1.100:4000/api/v1")!
    static let baseURL = URL(string: "https://dev.cookstemma.com/api/v1")!
    #else
    static let baseURL = URL(string: "https://cookstemma.com/api/v1")!
    #endif
    static let timeout: TimeInterval = 30
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoint

protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
    var requiresAuth: Bool { get }
}

extension APIEndpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
    var requiresAuth: Bool { true }
}

// MARK: - API Error

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case networkError(String)
    case unauthorized
    case forbidden
    case notFound
    case badRequest(String)
    case serverError(Int, String)
    case decodingError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError(let message):
            return "Data error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL), (.unauthorized, .unauthorized),
             (.forbidden, .forbidden), (.notFound, .notFound), (.unknown, .unknown):
            return true
        case let (.networkError(l), .networkError(r)),
             let (.badRequest(l), .badRequest(r)),
             let (.decodingError(l), .decodingError(r)):
            return l == r
        case let (.serverError(lCode, lMsg), .serverError(rCode, rMsg)):
            return lCode == rCode && lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - URLSession Protocol (for testing)

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Token Manager Protocol (for testing)

protocol TokenManagerProtocol: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var isAuthenticated: Bool { get }
    func saveTokens(accessToken: String, refreshToken: String)
    func refreshAccessToken() async throws
    func clearTokens()
}

// MARK: - API Client Protocol

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
    func uploadImage(_ imageData: Data, type: String) async throws -> ImageUploadResponse
}

// MARK: - Image Upload Response

struct ImageUploadResponse: Decodable {
    let imagePublicId: String
    let imageUrl: String
    let originalFilename: String?
}

// MARK: - API Client

final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private weak var tokenManager: TokenManagerProtocol?

    init(
        baseURL: URL = APIConfiguration.baseURL,
        session: URLSessionProtocol = URLSession.shared,
        tokenManager: TokenManagerProtocol? = nil,
        decoder: JSONDecoder = .apiDecoder,
        encoder: JSONEncoder = .apiEncoder
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenManager = tokenManager
        self.decoder = decoder
        self.encoder = encoder
    }

    func setTokenManager(_ tokenManager: TokenManagerProtocol) {
        self.tokenManager = tokenManager
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request: URLRequest
        do {
            request = try buildRequest(endpoint)
        } catch {
            #if DEBUG
            print("[API] Build request error: \(error)")
            #endif
            throw error
        }
        #if DEBUG
        print("[API] Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("[API] Body: \(bodyString)")
        }
        #endif
        let (data, response) = try await performRequest(request, endpoint: endpoint)
        #if DEBUG
        print("[API] Response: \(response.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[API] Data: \(String(jsonString.prefix(500)))")
        }
        #endif
        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[API] Decode error: \(error)")
            #endif
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func request(_ endpoint: APIEndpoint) async throws {
        let request = try buildRequest(endpoint)
        #if DEBUG
        print("[API] Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        #endif
        let (data, response) = try await performRequest(request, endpoint: endpoint)
        #if DEBUG
        print("[API] Response: \(response.statusCode)")
        if let jsonString = String(data: data, encoding: .utf8), !jsonString.isEmpty {
            print("[API] Data: \(String(jsonString.prefix(500)))")
        }
        #endif
        try validateResponse(response)
    }

    func uploadImage(_ imageData: Data, type: String) async throws -> ImageUploadResponse {
        let boundary = UUID().uuidString
        let url = baseURL.appendingPathComponent("images/upload")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        if let token = tokenManager?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        // Image file part
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        // Type part
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n")
        body.append(type)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        try validateResponse(httpResponse)
        return try decoder.decode(ImageUploadResponse.self, from: data)
    }

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = APIConfiguration.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        endpoint.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        // Always send auth token if available - this allows public endpoints
        // to return user-specific data (e.g., isSavedByCurrentUser)
        if let token = tokenManager?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if endpoint.requiresAuth {
            #if DEBUG
            print("[API] WARNING: No token available for authenticated endpoint: \(endpoint.path)")
            #endif
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func performRequest(_ request: URLRequest, endpoint: APIEndpoint) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }

            // Handle 401 - attempt token refresh
            if httpResponse.statusCode == 401 {
                if let tokenManager = tokenManager {
                    do {
                        try await tokenManager.refreshAccessToken()
                        // Retry with new token
                        var newRequest = request
                        if let newToken = tokenManager.accessToken {
                            newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                        }
                        let (retryData, retryResponse) = try await session.data(for: newRequest)
                        guard let retryHttpResponse = retryResponse as? HTTPURLResponse else { throw APIError.unknown }
                        return (retryData, retryHttpResponse)
                    } catch {
                        // Token refresh failed
                        tokenManager.clearTokens()
                        throw APIError.unauthorized
                    }
                }
            }
            return (data, httpResponse)
        } catch let error as APIError {
            #if DEBUG
            print("[API] APIError: \(error)")
            #endif
            throw error
        } catch let urlError as URLError {
            #if DEBUG
            print("[API] URLError: \(urlError.code) - \(urlError.localizedDescription)")
            #endif
            throw APIError.networkError("Network connection failed: \(urlError.localizedDescription)")
        } catch {
            #if DEBUG
            print("[API] Other error: \(type(of: error)) - \(error)")
            #endif
            throw APIError.networkError(error.localizedDescription)
        }
    }

    private func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299: return
        case 400: throw APIError.badRequest("Bad request")
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 404: throw APIError.notFound
        case 500...599: throw APIError.serverError(response.statusCode, "Server error")
        default: throw APIError.unknown
        }
    }
}

// MARK: - Type Erasure

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    init(_ value: Encodable) { self.encode = value.encode }
    func encode(to encoder: Encoder) throws { try encode(encoder) }
}

// MARK: - JSON Coders

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Backend uses camelCase - no conversion needed
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = ISO8601DateFormatter.fractional.date(from: dateString) { return date }
            if let date = ISO8601DateFormatter.standard.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }()
}

extension JSONEncoder {
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        // Backend expects camelCase - no conversion needed
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

// MARK: - Data Multipart Helper

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension ISO8601DateFormatter {
    static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
