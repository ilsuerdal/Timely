import Foundation

struct Meeting: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let duration: Int
    let platform: MeetingPlatform
    let participantEmail: String
    let meetingType: String
    
    init(id: String = UUID().uuidString, title: String, date: Date, duration: Int, platform: MeetingPlatform, participantEmail: String, meetingType: String) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.platform = platform
        self.participantEmail = participantEmail
        self.meetingType = meetingType
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

