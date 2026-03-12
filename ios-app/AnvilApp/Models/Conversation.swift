import Foundation

struct Conversation: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    
    init(title: String = "New Conversation", messages: [Message] = []) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation", 
           let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let preview = String(firstUserMessage.content.prefix(50))
            title = preview.contains("\n") ? String(preview.split(separator: "\n").first ?? "") : preview
        }
    }
    
    var lastMessage: Message? {
        return messages.last
    }
    
    var totalTokens: Int {
        return messages.compactMap { $0.usage?.totalTokens }.reduce(0, +)
    }
    
    var previewText: String {
        return lastMessage?.content ?? "No messages"
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

// MARK: - Core Data Extensions
#if canImport(CoreData)
import CoreData

extension Conversation {
    // Convert to Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> ConversationEntity {
        let entity = ConversationEntity(context: context)
        entity.id = id
        entity.title = title
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        
        // Convert messages to JSON
        if let messagesData = try? JSONEncoder().encode(messages) {
            entity.messagesData = messagesData
        }
        
        return entity
    }
    
    // Convert from Core Data entity
    static func fromCoreData(_ entity: ConversationEntity) -> Conversation? {
        guard let id = entity.id,
              let title = entity.title,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        var messages: [Message] = []
        
        if let messagesData = entity.messagesData,
           let decodedMessages = try? JSONDecoder().decode([Message].self, from: messagesData) {
            messages = decodedMessages
        }
        
        var conversation = Conversation(title: title, messages: messages)
        conversation.id = id
        conversation.createdAt = createdAt
        conversation.updatedAt = updatedAt
        
        return conversation
    }
}
#endif