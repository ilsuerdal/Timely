//
//  FirebaseDataManager.swift
//  TimelyNew
//
//  Created by ilsu on 20.06.2025.
//



import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseDataManager: ObservableObject {
    static let shared = FirebaseDataManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Meeting Types
    
    func saveMeetingType(_ meetingType: MeetingType, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        do {
            let meetingTypeData: [String: Any] = [
                "id": meetingType.id.uuidString,
                "name": meetingType.name,
                "duration": meetingType.duration,
                "platform": meetingType.platform.rawValue,
                "description": meetingType.description,
                "userId": userId,
                "createdAt": Timestamp(date: Date())
            ]
            
            db.collection("users").document(userId).collection("meetingTypes").document(meetingType.id.uuidString).setData(meetingTypeData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Toplantı türü kaydetme hatası: \(error)")
                        completion(false, error)
                    } else {
                        print("✅ Toplantı türü başarıyla kaydedildi: \(meetingType.name)")
                        completion(true, nil)
                    }
                }
            }
        } catch {
            completion(false, error)
        }
    }
    
    func loadMeetingTypes(completion: @escaping ([MeetingType], Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([], NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        db.collection("users").document(userId).collection("meetingTypes").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Toplantı türleri yükleme hatası: \(error)")
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                var meetingTypes: [MeetingType] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String,
                          let duration = data["duration"] as? Int,
                          let platformString = data["platform"] as? String,
                          let platform = MeetingPlatform(rawValue: platformString),
                          let description = data["description"] as? String else {
                        continue
                    }
                    
                    let meetingType = MeetingType(
                        id: id,
                        name: name,
                        duration: duration,
                        platform: platform,
                        description: description
                    )
                    
                    meetingTypes.append(meetingType)
                }
                
                print("✅ \(meetingTypes.count) toplantı türü yüklendi")
                completion(meetingTypes, nil)
            }
        }
    }
    
    // MARK: - Meetings
    
    func saveMeeting(_ meeting: Meeting, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        do {
            let meetingData: [String: Any] = [
                "id": meeting.id,
                "title": meeting.title,
                "date": Timestamp(date: meeting.date),
                "duration": meeting.duration,
                "platform": meeting.platform.rawValue,
                "participantEmail": meeting.participantEmail,
                "meetingType": meeting.meetingType,
                "userId": userId,
                "createdAt": Timestamp(date: Date())
            ]
            
            db.collection("users").document(userId).collection("meetings").document(meeting.id).setData(meetingData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Toplantı kaydetme hatası: \(error)")
                        completion(false, error)
                    } else {
                        print("✅ Toplantı başarıyla kaydedildi: \(meeting.title)")
                        completion(true, nil)
                    }
                }
            }
        } catch {
            completion(false, error)
        }
    }
    
    func loadMeetings(completion: @escaping ([Meeting], Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([], NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        db.collection("users").document(userId).collection("meetings").order(by: "date").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Toplantılar yükleme hatası: \(error)")
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                var meetings: [Meeting] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let id = data["id"] as? String,
                          let title = data["title"] as? String,
                          let dateTimestamp = data["date"] as? Timestamp,
                          let duration = data["duration"] as? Int,
                          let platformString = data["platform"] as? String,
                          let platform = MeetingPlatform(rawValue: platformString),
                          let participantEmail = data["participantEmail"] as? String,
                          let meetingType = data["meetingType"] as? String else {
                        continue
                    }
                    
                    let meeting = Meeting(
                        id: id,
                        title: title,
                        date: dateTimestamp.dateValue(),
                        duration: duration,
                        platform: platform,
                        participantEmail: participantEmail,
                        meetingType: meetingType
                    )
                    
                    meetings.append(meeting)
                }
                
                print("✅ \(meetings.count) toplantı yüklendi")
                completion(meetings, nil)
            }
        }
    }
    
    // MARK: - Availability
    
    func saveAvailability(_ availability: Availability, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        let availabilityData: [String: Any] = [
            "workDays": availability.workDays.map { $0.rawValue },
            "startTime": Timestamp(date: availability.startTime),
            "endTime": Timestamp(date: availability.endTime),
            "timezone": availability.timezone,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).updateData(["availability": availabilityData]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Müsaitlik kaydetme hatası: \(error)")
                    completion(false, error)
                } else {
                    print("✅ Müsaitlik başarıyla kaydedildi")
                    completion(true, nil)
                }
            }
        }
    }
    
    func loadAvailability(completion: @escaping (Availability?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Müsaitlik yükleme hatası: \(error)")
                    completion(nil, error)
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data(),
                      let availabilityData = data["availability"] as? [String: Any] else {
                    // Varsayılan müsaitlik döndür
                    let defaultAvailability = Availability(
                        workDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                        startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
                        endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date(),
                        timezone: TimeZone.current.identifier
                    )
                    completion(defaultAvailability, nil)
                    return
                }
                
                guard let workDaysStrings = availabilityData["workDays"] as? [String],
                      let startTimeTimestamp = availabilityData["startTime"] as? Timestamp,
                      let endTimeTimestamp = availabilityData["endTime"] as? Timestamp,
                      let timezone = availabilityData["timezone"] as? String else {
                    completion(nil, NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Müsaitlik verisi geçersiz"]))
                    return
                }
                
                let workDays = Set(workDaysStrings.compactMap { WeekDay(rawValue: $0) })
                
                let availability = Availability(
                    workDays: workDays,
                    startTime: startTimeTimestamp.dateValue(),
                    endTime: endTimeTimestamp.dateValue(),
                    timezone: timezone
                )
                
                print("✅ Müsaitlik yüklendi")
                completion(availability, nil)
            }
        }
    }
}

// Meeting.swift - Güncellenmiş model

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
        return formatter.string(from: date)
    }
}

// MeetingType.swift - Güncellenmiş model

struct MeetingType: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: Int
    var platform: MeetingPlatform
    var description: String
    
    init(id: UUID = UUID(), name: String, duration: Int, platform: MeetingPlatform, description: String) {
        self.id = id
        self.name = name
        self.duration = duration
        self.platform = platform
        self.description = description
    }
}
