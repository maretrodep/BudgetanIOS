import Foundation

struct Expense: Identifiable, Codable {
    let id: Int
    let amount: Double
    let time: Date
    let category: String
    let priority: String
    let status: String
    let mood: String
    let note: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, amount, time, category, priority, status, mood, note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        
        // For date decoding
        let timeString = try container.decode(String.self, forKey: .time)
        
        // Try multiple date formats
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = dateFormatter.date(from: timeString) {
            time = date
        } else {
            // Try an alternative format
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = dateFormatter.date(from: timeString) {
                time = date
            } else {
                // Default to ISO8601
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = iso8601Formatter.date(from: timeString) {
                    time = date
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .time,
                                                         in: container,
                                                         debugDescription: "Cannot decode date string: \(timeString)")
                }
            }
        }
        
        category = try container.decode(String.self, forKey: .category)
        priority = try container.decode(String.self, forKey: .priority)
        status = try container.decode(String.self, forKey: .status)
        mood = try container.decode(String.self, forKey: .mood)
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
    
    // Add custom encoding if needed
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(amount, forKey: .amount)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timeString = formatter.string(from: time)
        try container.encode(timeString, forKey: .time)
        
        try container.encode(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(status, forKey: .status)
        try container.encode(mood, forKey: .mood)
        try container.encodeIfPresent(note, forKey: .note)
    }
}
