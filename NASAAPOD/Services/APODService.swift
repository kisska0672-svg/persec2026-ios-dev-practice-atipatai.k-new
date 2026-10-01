import Foundation

enum APODServiceError: LocalizedError {
    case invalidURL
    case badResponse
    case rateLimit(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Cannot create NASA API URL."
        case .badResponse:
            return "NASA API returned an invalid response."
        case .rateLimit(let message):
            return "NASA API rate limit exceeded. \(message)"
        case .server(let message):
            return message
        }
    }
}

protocol APODServing {
    func fetchItems(startDate: Date, endDate: Date) async throws -> [APODItem]
}

struct APODService: APODServing {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = APODService.defaultSession, apiKey: String = APODService.defaultAPIKey) {
        self.session = session
        self.apiKey = Self.validAPIKey(apiKey) ?? Self.demoAPIKey
    }

    func fetchItems(startDate: Date, endDate: Date) async throws -> [APODItem] {
        do {
            return try await fetchItems(startDate: startDate, endDate: endDate, apiKey: apiKey)
        } catch APODServiceError.rateLimit where apiKey != Self.demoAPIKey {
            #if DEBUG
            print("NASA APOD primary API key quota reached; retrying with DEMO_KEY")
            #endif
            return try await fetchItems(startDate: startDate, endDate: endDate, apiKey: Self.demoAPIKey)
        }
    }

    private func fetchItems(startDate: Date, endDate: Date, apiKey: String) async throws -> [APODItem] {
        var components = URLComponents(string: "https://science.nasa.gov/wp-json/wp/v2/apod-basic/")
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "per_page", value: "31"),
            URLQueryItem(name: "orderby", value: "date"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "after", value: Self.apiDateTimeFormatter.string(from: startDate)),
            URLQueryItem(name: "before", value: Self.apiDateTimeFormatter.string(from: Self.dayAfter(endDate)))
        ]

        guard let url = components?.url else {
            throw APODServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        #if DEBUG
        if let redactedURL = Self.redactedAPIKeyURL(from: url) {
            print("NASA APOD request: \(redactedURL.absoluteString)")
        }
        #endif

        let (data, response) = try await Self.withTimeout(seconds: 20) {
            try await session.data(for: request)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("NASA APOD response was not HTTPURLResponse")
            throw APODServiceError.badResponse
        }

        print("NASA APOD response status: \(httpResponse.statusCode), bytes: \(data.count)")

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data.prefix(500), encoding: .utf8) ?? "Unable to read response body."
            print("NASA APOD error body: \(body)")

            if let apiError = try? JSONDecoder().decode(APODAPIError.self, from: data) {
                if httpResponse.statusCode == 429 || apiError.code == "OVER_RATE_LIMIT" {
                    throw APODServiceError.rateLimit(apiError.message)
                }
                throw APODServiceError.server(apiError.message)
            }
            throw APODServiceError.server("NASA API error: \(httpResponse.statusCode)")
        }

        APODService.printResponseBody(data)

        let decoder = JSONDecoder()
        let items: [APODItem]

        do {
            items = try decoder.decode([APODItem].self, from: data)
            print("NASA APOD decoded response item count: \(items.count)")
            items.prefix(5).forEach { item in
                print("NASA APOD decoded item: date=\(item.date), title=\(item.title), mediaType=\(item.mediaType), url=\(item.url?.absoluteString ?? "-")")
            }
        } catch {
            let preview = String(data: data.prefix(300), encoding: .utf8) ?? "Unable to read response body."
            print("NASA APOD decode failed: \(error.localizedDescription)")
            throw APODServiceError.server("Cannot decode NASA response. \(preview)")
        }

        let startText = Self.apiDateFormatter.string(from: startDate)
        let endText = Self.apiDateFormatter.string(from: endDate)
        return items
            .filter { $0.date >= startText && $0.date <= endText }
            .sorted { $0.date > $1.date }
    }

    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    private static func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw APODServiceError.server("Request timed out after \(Int(seconds)) seconds.")
            }

            guard let result = try await group.next() else {
                throw APODServiceError.badResponse
            }

            group.cancelAll()
            return result
        }
    }

    private static func redactedAPIKeyURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems = components.queryItems?.map { item in
            item.name == "api_key" ? URLQueryItem(name: item.name, value: "<redacted>") : item
        }

        return components.url
    }

    private static func printResponseBody(_ data: Data) {
        let maxCharacters = 4_000

        guard let body = String(data: data, encoding: .utf8) else {
            print("NASA APOD response body: <unable to read as UTF-8>")
            return
        }

        if body.count > maxCharacters {
            let preview = String(body.prefix(maxCharacters))
            print("NASA APOD response body preview (\(maxCharacters)/\(body.count) chars): \(preview)")
        } else {
            print("NASA APOD response body: \(body)")
        }
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let apiDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    private static func dayAfter(_ date: Date) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date) ?? date
    }

    private static var defaultAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String else {
            return demoAPIKey
        }

        return validAPIKey(key) ?? demoAPIKey
    }

    private static let demoAPIKey = "DEMO_KEY"

    private static func validAPIKey(_ key: String?) -> String? {
        guard let key else { return nil }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey.isEmpty == false,
              (trimmedKey.hasPrefix("$(") && trimmedKey.hasSuffix(")")) == false else {
            return nil
        }

        return trimmedKey
    }
}

private struct APODAPIError: Decodable {
    let msg: String?
    let error: ErrorBody?

    var code: String? {
        error?.code
    }

    var message: String {
        msg ?? error?.message ?? "NASA API returned an error."
    }

    struct ErrorBody: Decodable {
        let code: String?
        let message: String
    }
}
