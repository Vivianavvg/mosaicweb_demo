import Foundation

public struct AgentSuggestion: Identifiable, Hashable, Codable {
    public var id: String
    public var label: String
    public var action: String
    public var prompt: String?

    public init(id: String? = nil, label: String, action: String, prompt: String? = nil) {
        self.label = label
        self.action = action
        self.prompt = prompt
        self.id = id ?? label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        action = try container.decodeIfPresent(String.self, forKey: .action) ?? "ask"
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? label
    }

    public var destinationTab: Int? {
        switch action {
        case "review_changes": return 1
        case "open_recovery": return 2
        case "open_learn": return 3
        default: return nil
        }
    }
}

public struct AgentTurn: Codable {
    public var summary: String
    public var reply: String?
    public var suggestions: [AgentSuggestion]
    public var memories: [String]

    public init(
        summary: String,
        reply: String? = nil,
        suggestions: [AgentSuggestion] = [],
        memories: [String] = []
    ) {
        self.summary = summary
        self.reply = reply
        self.suggestions = suggestions
        self.memories = memories
    }
}

public struct AgentMessage: Identifiable, Hashable {
    public enum Role: String {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public let text: String
    public let createdAt: Date

    public init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}
