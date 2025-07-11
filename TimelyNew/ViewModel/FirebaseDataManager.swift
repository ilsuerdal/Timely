import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseDataManager: ObservableObject {
    static let shared = FirebaseDataManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Availability (Müsaitlik Ayarları)
    
    func saveAvailability(_ availability: Availability, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        print("🔄 Müsaitlik kaydediliyor...")
        print("📋 Kaydedilecek veriler:")
        print("   - User ID: \(userId)")
        print("   - Çalışma Günleri: \(availability.workDays.map { $0.rawValue })")
        print("   - Başlangıç: \(availability.startTime)")
        print("   - Bitiş: \(availability.endTime)")
        print("   - Saat Dilimi: \(availability.timezone)")
        
        // Background queue'da Firebase işlemini yap
        DispatchQueue.global(qos: .userInitiated).async {
            // DateFormatter ile saat formatını kontrol et
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            let availabilityData: [String: Any] = [
                "workDays": availability.workDays.map { $0.rawValue },
                "startTime": Timestamp(date: availability.startTime),
                "endTime": Timestamp(date: availability.endTime),
                "timezone": availability.timezone,
                "updatedAt": Timestamp(date: Date()),
                // Debug için ek bilgiler
                "startTimeString": timeFormatter.string(from: availability.startTime),
                "endTimeString": timeFormatter.string(from: availability.endTime)
            ]
            
            print("📤 Firebase'e gönderilecek data: \(availabilityData)")
            
            // Kullanıcı belgesine müsaitlik bilgilerini kaydet
            self.db.collection("users").document(userId).setData(["availability": availabilityData], merge: true) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Müsaitlik kaydetme hatası: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        print("✅ Müsaitlik başarıyla Firebase'e kaydedildi")
                        // Kontrol amaçlı kaydedilen veriyi geri oku (background'da)
                        DispatchQueue.global(qos: .background).async {
                            self.verifyAvailabilitySaved(userId: userId)
                        }
                        completion(true, nil)
                    }
                }
            }
        }
    }
    
    private func verifyAvailabilitySaved(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let availabilityData = document.data()?["availability"] as? [String: Any] {
                    print("🔍 Verification - Kaydedilen müsaitlik verisi:")
                    print("   - workDays: \(availabilityData["workDays"] ?? "nil")")
                    print("   - startTimeString: \(availabilityData["startTimeString"] ?? "nil")")
                    print("   - endTimeString: \(availabilityData["endTimeString"] ?? "nil")")
                    print("   - timezone: \(availabilityData["timezone"] ?? "nil")")
                } else {
                    print("❌ Verification failed - Müsaitlik verisi bulunamadı")
                }
            } else {
                print("❌ Verification failed - Kullanıcı belgesi bulunamadı: \(error?.localizedDescription ?? "Bilinmeyen hata")")
            }
        }
    }
    
    func loadAvailability(completion: @escaping (Availability?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        print("🔄 Müsaitlik yükleniyor...")
        
        // Background queue'da Firebase işlemini yap
        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("users").document(userId).getDocument { document, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Müsaitlik yükleme hatası: \(error.localizedDescription)")
                        completion(nil, error)
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        print("📝 Kullanıcı belgesi bulunamadı, varsayılan müsaitlik döndürülüyor")
                        let defaultAvailability = self.createDefaultAvailability()
                        completion(defaultAvailability, nil)
                        return
                    }
                    
                    guard let data = document.data(),
                          let availabilityData = data["availability"] as? [String: Any] else {
                        print("📝 Müsaitlik verisi bulunamadı, varsayılan müsaitlik döndürülüyor")
                        let defaultAvailability = self.createDefaultAvailability()
                        completion(defaultAvailability, nil)
                        return
                    }
                    
                    print("📥 Firebase'den alınan müsaitlik verisi: \(availabilityData)")
                    
                    // Veriyi parse et
                    guard let workDaysStrings = availabilityData["workDays"] as? [String],
                          let startTimeTimestamp = availabilityData["startTime"] as? Timestamp,
                          let endTimeTimestamp = availabilityData["endTime"] as? Timestamp,
                          let timezone = availabilityData["timezone"] as? String else {
                        print("❌ Müsaitlik verisi geçersiz format")
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
                    
                    // Safe date formatting
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    
                    print("✅ Müsaitlik başarıyla yüklendi:")
                    print("   - Çalışma Günleri: \(workDays.map { $0.rawValue })")
                    print("   - Başlangıç: \(timeFormatter.string(from: availability.startTime))")
                    print("   - Bitiş: \(timeFormatter.string(from: availability.endTime))")
                    print("   - Saat Dilimi: \(availability.timezone)")
                    
                    completion(availability, nil)
                }
            }
        }
    }
    
    private func createDefaultAvailability() -> Availability {
        let calendar = Calendar.current
        let today = Date()
        
        // Create safe dates with full date components
        var startComponents = calendar.dateComponents([.year, .month, .day], from: today)
        startComponents.hour = 9
        startComponents.minute = 0
        startComponents.second = 0
        startComponents.nanosecond = 0
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: today)
        endComponents.hour = 17
        endComponents.minute = 0
        endComponents.second = 0
        endComponents.nanosecond = 0
        
        let startTime = calendar.date(from: startComponents) ?? Date()
        let endTime = calendar.date(from: endComponents) ?? Date()
        
        return Availability(
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            startTime: startTime,
            endTime: endTime,
            timezone: TimeZone.current.identifier
        )
    }
    
    // MARK: - Meeting Types
    
    func saveMeetingType(_ meetingType: MeetingType, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let meetingTypeData: [String: Any] = [
                "id": meetingType.id.uuidString,
                "name": meetingType.name,
                "duration": meetingType.duration,
                "platform": meetingType.platform.rawValue,
                "description": meetingType.description,
                "userId": userId,
                "createdAt": Timestamp(date: Date())
            ]
            
            self.db.collection("users").document(userId).collection("meetingTypes").document(meetingType.id.uuidString).setData(meetingTypeData) { error in
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
        }
    }
    
    func loadMeetingTypes(completion: @escaping ([MeetingType], Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion([], NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("users").document(userId).collection("meetingTypes").getDocuments { snapshot, error in
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
    }
    
    // MARK: - Meetings
    
    func saveMeeting(_ meeting: Meeting, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
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
            
            self.db.collection("users").document(userId).collection("meetings").document(meeting.id).setData(meetingData) { error in
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
        }
    }
    
    func loadMeetings(completion: @escaping ([Meeting], Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion([], NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı giriş yapmamış"]))
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.db.collection("users").document(userId).collection("meetings").order(by: "date").getDocuments { snapshot, error in
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
    }
}
