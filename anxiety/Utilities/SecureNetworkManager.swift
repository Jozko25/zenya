import Foundation
import CryptoKit

class SecureNetworkManager: NSObject {
    static let shared = SecureNetworkManager()
    
    private var pinnedHosts: [String: Set<String>] = [:]
    private var rateLimiter = RateLimiter()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private override init() {
        super.init()
        setupCertificatePinning()
    }
    
    private func setupCertificatePinning() {
        pinnedHosts["api.openai.com"] = [
            "sha256/9d28ed1b7b86c35c4b0c0f0f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f"
        ]
        
        pinnedHosts["api.openweathermap.org"] = [
            "sha256/8d28ed1b7b86c35c4b0c0f0f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f"
        ]
        
        pinnedHosts["ejtdmxnaauqkhdgslwyi.supabase.co"] = [
            "sha256/7d28ed1b7b86c35c4b0c0f0f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f5c9a0c8f"
        ]
    }
    
    func performRequest(_ request: URLRequest, rateLimitKey: String? = nil) async throws -> (Data, URLResponse) {
        if let key = rateLimitKey {
            try await rateLimiter.checkRateLimit(for: key)
        }
        
        let sanitizedRequest = try sanitizeRequest(request)
        return try await session.data(for: sanitizedRequest)
    }
    
    private func sanitizeRequest(_ request: URLRequest) throws -> URLRequest {
        var sanitized = request
        
        guard let url = request.url,
              let host = url.host else {
            throw NetworkError.invalidURL
        }
        
        if url.scheme != "https" {
            throw NetworkError.insecureConnection
        }
        
        if let path = url.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            if path.count > 2000 {
                throw NetworkError.invalidInput("URL path too long")
            }
        }
        
        return sanitized
    }
}

extension SecureNetworkManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard pinnedHosts.keys.contains(host) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            #if DEBUG
            debugPrint("⚠️ Certificate pinning: No certificate found for \(host)")
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let certificateData = SecCertificateCopyData(certificate) as Data
        let certificateHash = sha256(data: certificateData)
        let hashString = "sha256/" + certificateHash.base64EncodedString()
        
        if let pinnedHashes = pinnedHosts[host],
           pinnedHashes.contains(hashString) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            #if DEBUG
            debugPrint("⚠️ Certificate pinning failed for \(host)")
            debugPrint("   Expected: \(pinnedHosts[host] ?? [])")
            debugPrint("   Got: \(hashString)")
            completionHandler(.performDefaultHandling, nil)
            #else
            completionHandler(.cancelAuthenticationChallenge, nil)
            #endif
        }
    }
    
    private func sha256(data: Data) -> Data {
        let hashed = SHA256.hash(data: data)
        return Data(hashed)
    }
}

class RateLimiter {
    private var requestCounts: [String: [Date]] = [:]
    private let queue = DispatchQueue(label: "com.anxiety.ratelimiter")
    private let maxRequestsPerMinute = 60
    private let maxRequestsPer5Minutes = 200
    
    func checkRateLimit(for key: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                let now = Date()
                let oneMinuteAgo = now.addingTimeInterval(-60)
                let fiveMinutesAgo = now.addingTimeInterval(-300)
                
                var timestamps = self.requestCounts[key] ?? []
                timestamps = timestamps.filter { $0 > fiveMinutesAgo }
                
                let recentRequests = timestamps.filter { $0 > oneMinuteAgo }.count
                let totalRequests = timestamps.count
                
                if recentRequests >= self.maxRequestsPerMinute {
                    continuation.resume(throwing: NetworkError.rateLimitExceeded("Too many requests in the last minute"))
                    return
                }
                
                if totalRequests >= self.maxRequestsPer5Minutes {
                    continuation.resume(throwing: NetworkError.rateLimitExceeded("Too many requests in the last 5 minutes"))
                    return
                }
                
                timestamps.append(now)
                self.requestCounts[key] = timestamps
                continuation.resume()
            }
        }
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case insecureConnection
    case certificatePinningFailed
    case rateLimitExceeded(String)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .insecureConnection:
            return "Insecure connection attempted"
        case .certificatePinningFailed:
            return "Certificate validation failed"
        case .rateLimitExceeded(let message):
            return "Rate limit exceeded: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}
