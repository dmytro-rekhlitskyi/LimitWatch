import Foundation

final class ClaudeAPIService {
    private let baseURL = "https://claude.ai/api/organizations"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpCookieAcceptPolicy = .always
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private func applyHeaders(to request: inout URLRequest, sessionKey: String) {
        let headers: [String: String] = [
            "accept": "*/*",
            "accept-language": "en-US,en;q=0.9",
            "content-type": "application/json",
            "anthropic-client-platform": "web_claude_ai",
            "anthropic-client-version": "1.0.0",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "origin": "https://claude.ai",
            "referer": "https://claude.ai/settings/usage",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "Cookie": "sessionKey=\(sessionKey)"
        ]
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    }

    // MARK: - Fetch organizations (used during login)

    func fetchOrganizations(sessionKey: String, completion: @escaping (Result<[OrganizationResponse], Error>) -> Void) {
        guard let url = URL(string: "https://claude.ai/api/organizations") else {
            completion(.failure(APIError.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request, sessionKey: sessionKey)

        session.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async { completion(.failure(APIError.networkError)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 401: DispatchQueue.main.async { completion(.failure(APIError.unauthorized)) }; return
                case 403: DispatchQueue.main.async { completion(.failure(APIError.cloudflareBlocked)) }; return
                default: break
                }
            }
            do {
                let orgs = try JSONDecoder().decode([OrganizationResponse].self, from: data)
                DispatchQueue.main.async { completion(.success(orgs)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(APIError.decodingError)) }
            }
        }.resume()
    }

    // MARK: - Fetch usage data

    func fetchUsage(sessionKey: String, organizationId: String, completion: @escaping (Result<ClaudeUsageData, Error>) -> Void) {
        let urlString = "\(baseURL)/\(organizationId)/usage"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request, sessionKey: sessionKey)

        session.dataTask(with: request) { data, response, error in
            if error != nil {
                DispatchQueue.main.async { completion(.failure(APIError.networkError)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }

            // Check for HTML (Cloudflare block)
            if let text = String(data: data, encoding: .utf8),
               text.contains("<!DOCTYPE html>") || text.contains("<html") {
                DispatchQueue.main.async { completion(.failure(APIError.cloudflareBlocked)) }
                return
            }

            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 401: DispatchQueue.main.async { completion(.failure(APIError.unauthorized)) }; return
                case 403: DispatchQueue.main.async { completion(.failure(APIError.cloudflareBlocked)) }; return
                default: break
                }
            }

            // Check for permission_error in body
            if let errorResp = try? JSONDecoder().decode(ErrorBody.self, from: data),
               errorResp.error?.type == "permission_error" {
                DispatchQueue.main.async { completion(.failure(APIError.sessionExpired)) }
                return
            }

            do {
                let wire = try JSONDecoder().decode(UsageResponse.self, from: data)
                let usageData = wire.toClaudeUsageData()
                DispatchQueue.main.async { completion(.success(usageData)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(APIError.decodingError)) }
            }
        }.resume()
    }
}

// MARK: - Wire models

private struct UsageResponse: Codable {
    let five_hour: LimitUsage
    let seven_day: LimitUsage?

    struct LimitUsage: Codable {
        let utilization: Double
        let resets_at: String?
    }

    func toClaudeUsageData() -> ClaudeUsageData {
        ClaudeUsageData(
            fiveHourPercentage: five_hour.utilization,
            sevenDayPercentage: seven_day?.utilization ?? 0,
            fiveHourResetsAt: parseDate(five_hour.resets_at),
            sevenDayResetsAt: parseDate(seven_day?.resets_at),
            lastUpdated: Date()
        )
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: str) else { return nil }
        return Date(timeIntervalSinceReferenceDate: round(date.timeIntervalSinceReferenceDate))
    }
}

private struct ErrorBody: Codable {
    let error: ErrorDetail?
    struct ErrorDetail: Codable {
        let type: String?
    }
}
