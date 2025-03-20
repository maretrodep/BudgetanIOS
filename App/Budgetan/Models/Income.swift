import Foundation

struct Income: Identifiable, Codable {
    let id: Int
    let amount: Double
    let time: Date
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, time, note
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
        
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }
}
