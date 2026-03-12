import Foundation

struct Message: Codable, Identifiable, Hashable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    let toolCalls: [ToolCall]?
    let usage: TokenUsage?
    
    enum MessageRole: String, Codable, CaseIterable {
        case user
        case assistant
        case system
        
        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "Anvil"
            case .system: return "System"
            }
        }
    }
    
    init(role: MessageRole, content: String, toolCalls: [ToolCall]? = nil, usage: TokenUsage? = nil) {
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.toolCalls = toolCalls
        self.usage = usage
    }
}

struct ToolCall: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let parameters: [String: AnyCodable]
    let result: String?
    
    enum CodingKeys: String, CodingKey {
        case name, parameters, result
    }
}

struct TokenUsage: Codable, Hashable {
    let inputTokens: Int
    let outputTokens: Int
    
    var totalTokens: Int {
        return inputTokens + outputTokens
    }
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// Helper for encoding/decoding arbitrary JSON
struct AnyCodable: Codable, Hashable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { AnyCodable($0) }
            try container.encode(codableArray)
        case let dictValue as [String: Any]:
            let codableDict = dictValue.mapValues { AnyCodable($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check - in production you might want more sophisticated comparison
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}