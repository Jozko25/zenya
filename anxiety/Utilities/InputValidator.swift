import Foundation

class InputValidator {
    static let shared = InputValidator()
    
    private init() {}
    
    func validateJournalEntry(_ text: String) throws -> String {
        guard !text.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard text.count <= 50000 else {
            throw ValidationError.inputTooLong(max: 50000)
        }
        
        let sanitized = sanitizeText(text)
        return sanitized
    }
    
    func validateUserName(_ name: String) throws -> String {
        guard !name.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard name.count <= 100 else {
            throw ValidationError.inputTooLong(max: 100)
        }
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmed.count >= 1 else {
            throw ValidationError.emptyInput
        }
        
        let sanitized = sanitizeText(trimmed)
        return sanitized
    }
    
    func validateActivationCode(_ code: String) throws -> String {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let pattern = "^ZENYA-[A-Z0-9]{4}-[A-Z0-9]{4}(-[A-Z0-9]{4})?$"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(cleaned.startIndex..., in: cleaned)
        
        guard regex.firstMatch(in: cleaned, range: range) != nil else {
            throw ValidationError.invalidFormat("Activation code must be in format: ZENYA-XXXX-XXXX")
        }
        
        return cleaned
    }
    
    func validateEmail(_ email: String) throws -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        
        guard regex.firstMatch(in: trimmed, range: range) != nil else {
            throw ValidationError.invalidFormat("Invalid email format")
        }
        
        return trimmed.lowercased()
    }
    
    func validateURL(_ urlString: String) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw ValidationError.invalidFormat("Invalid URL")
        }
        
        guard url.scheme == "https" else {
            throw ValidationError.insecureInput("Only HTTPS URLs are allowed")
        }
        
        guard let host = url.host, !host.isEmpty else {
            throw ValidationError.invalidFormat("URL must have a valid host")
        }
        
        return url
    }
    
    func validateMoodValue(_ value: Double) throws -> Double {
        guard value >= 0 && value <= 10 else {
            throw ValidationError.doubleOutOfRange(min: 0, max: 10)
        }
        return value
    }
    
    func validateAnxietyLevel(_ value: Int) throws -> Int {
        guard value >= 1 && value <= 10 else {
            throw ValidationError.intOutOfRange(min: 1, max: 10)
        }
        return value
    }
    
    func sanitizeText(_ text: String) -> String {
        var sanitized = text
        
        sanitized = sanitized.replacingOccurrences(of: "<script", with: "&lt;script", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "</script>", with: "&lt;/script&gt;", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "onerror=", with: "", options: .caseInsensitive)
        sanitized = sanitized.replacingOccurrences(of: "onclick=", with: "", options: .caseInsensitive)
        
        return sanitized
    }
    
    func validateAndSanitizeEndpoint(_ endpoint: String) throws -> String {
        guard !endpoint.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard endpoint.count <= 500 else {
            throw ValidationError.inputTooLong(max: 500)
        }
        
        let invalidChars = CharacterSet(charactersIn: ";'\"\\")
        guard endpoint.rangeOfCharacter(from: invalidChars) == nil else {
            throw ValidationError.invalidCharacters("Endpoint contains invalid characters")
        }
        
        return endpoint
    }
    
    func validateUUID(_ uuidString: String) throws -> UUID {
        guard let uuid = UUID(uuidString: uuidString) else {
            throw ValidationError.invalidFormat("Invalid UUID format")
        }
        return uuid
    }
    
    func sanitizeForSQL(_ text: String) -> String {
        var sanitized = text
        sanitized = sanitized.replacingOccurrences(of: "'", with: "''")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "\\\\")
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        return sanitized
    }
    
    func validateDuration(_ seconds: Int) throws -> Int {
        guard seconds > 0 else {
            throw ValidationError.invalidValue("Duration must be positive")
        }
        
        guard seconds <= 86400 else {
            throw ValidationError.intOutOfRange(min: 1, max: 86400)
        }
        
        return seconds
    }
    
    func validatePoints(_ points: Int) throws -> Int {
        guard points >= 0 else {
            throw ValidationError.invalidValue("Points cannot be negative")
        }
        
        guard points <= 1000000 else {
            throw ValidationError.intOutOfRange(min: 0, max: 1000000)
        }
        
        return points
    }
}

enum ValidationError: LocalizedError {
    case emptyInput
    case inputTooLong(max: Int)
    case invalidFormat(String)
    case invalidCharacters(String)
    case intOutOfRange(min: Int, max: Int)
    case doubleOutOfRange(min: Double, max: Double)
    case invalidValue(String)
    case insecureInput(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case .inputTooLong(let max):
            return "Input is too long (maximum: \(max) characters)"
        case .invalidFormat(let message):
            return message
        case .invalidCharacters(let message):
            return message
        case .intOutOfRange(let min, let max):
            return "Value must be between \(min) and \(max)"
        case .doubleOutOfRange(let min, let max):
            return "Value must be between \(min) and \(max)"
        case .invalidValue(let message):
            return message
        case .insecureInput(let message):
            return message
        }
    }
}
