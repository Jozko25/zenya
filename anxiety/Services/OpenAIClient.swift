//
//  OpenAIClient.swift
//  anxiety
//
//  Shared OpenAI API client for AI services
//

import Foundation

// MARK: - OpenAI Client

class OpenAIClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init() {
        // Load API key from plist file
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["OpenAI_API_Key"] as? String,
              !key.isEmpty && key != "your-actual-api-key-here" else {
            debugPrint("⚠️ OpenAI API key not configured in APIKeys.plist - AI features will use fallback content")
            debugPrint("💡 To enable AI question generation, add your OpenAI API key to anxiety/Config/APIKeys.plist")
            self.apiKey = ""
            return
        }
        self.apiKey = key
        debugPrint("✅ OpenAI API key loaded successfully - AI features enabled")
    }

    func sendMessage(_ message: String, conversationHistory: [SimpleChatMessage], systemPrompt: String? = nil) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        // Use provided system prompt or default
        let finalSystemPrompt = systemPrompt ?? """
        You are a helpful AI assistant. Provide clear, accurate, and helpful responses.
        """

        var messages: [[String: Any]] = [
            ["role": "system", "content": finalSystemPrompt]
        ]

        // Add conversation history if provided
        for chatMessage in conversationHistory {
            messages.append([
                "role": chatMessage.isFromUser ? "user" : "assistant",
                "content": chatMessage.content
            ])
        }

        // Add current message
        messages.append([
            "role": "user",
            "content": message
        ])

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30 // 30 second timeout for API requests
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                debugPrint("❌ OpenAI API Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    debugPrint("Error details: \(errorData)")
                }
                throw OpenAIError.apiError(httpResponse.statusCode)
            }

            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = jsonResponse?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw OpenAIError.invalidResponse
            }

            return content.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidRequest
    case invalidResponse
    case apiError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidRequest:
            return "Invalid request format"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            return "API error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Simple Chat Message Model for API Calls

struct SimpleChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let date: Date

    init(content: String, isFromUser: Bool, date: Date) {
        self.content = content
        self.isFromUser = isFromUser
        self.date = date
    }
}