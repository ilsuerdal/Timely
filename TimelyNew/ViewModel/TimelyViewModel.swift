import SwiftUI
import Foundation
import FirebaseAuth

class TimelyViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var meetingTypes: [MeetingType] = []
    @Published var contacts: [Contact] = []
    @Published var availability: Availability
    @Published var selectedTab: TabItem = .home
    @Published var isLoadingAvailability = false
    
    init() {
        // Default availability
        self.availability = Self.createDefaultAvailability()
        
        setupSampleData()
        loadDataFromFirebase()
    }
    
    private static func createDefaultAvailability() -> Availability {
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
    
    // MARK: - Firebase Data Loading
    
    private func loadDataFromFirebase() {
        loadAvailabilityFromFirebase()
        loadMeetingTypesFromFirebase()
        loadMeetingsFromFirebase()
    }
    
    private func loadAvailabilityFromFirebase() {
        isLoadingAvailability = true
        
        FirebaseDataManager.shared.loadAvailability { [weak self] availability, error in
            DispatchQueue.main.async {
                self?.isLoadingAvailability = false
                
                if let availability = availability {
                    self?.availability = availability
                    print("✅ ViewModel: Müsaitlik ayarları yüklendi")
                } else if let error = error {
                    print("❌ ViewModel: Müsaitlik yükleme hatası: \(error)")
                    // Hata durumunda varsayılan ayarları koru
                }
            }
        }
    }
    
    private func loadMeetingTypesFromFirebase() {
        FirebaseDataManager.shared.loadMeetingTypes { [weak self] meetingTypes, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ ViewModel: Toplantı türleri yükleme hatası: \(error)")
                } else {
                    // Firebase'den gelen verilerle sample data'yı birleştir
                    let firebaseMeetingTypes = meetingTypes
                    if firebaseMeetingTypes.isEmpty {
                        // Firebase'de veri yoksa sample data'yı kullan
                        print("📝 ViewModel: Firebase'de toplantı türü yok, sample data kullanılıyor")
                    } else {
                        self?.meetingTypes = firebaseMeetingTypes
                        print("✅ ViewModel: \(firebaseMeetingTypes.count) toplantı türü Firebase'den yüklendi")
                    }
                }
            }
        }
    }
    
    private func loadMeetingsFromFirebase() {
        FirebaseDataManager.shared.loadMeetings { [weak self] meetings, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ ViewModel: Toplantılar yükleme hatası: \(error)")
                } else {
                    self?.meetings = meetings
                    print("✅ ViewModel: \(meetings.count) toplantı Firebase'den yüklendi")
                    // Contacts'ı güncelle
                    self?.updateContactsFromMeetings()
                }
            }
        }
    }
    
    // MARK: - Sample Data Setup
    
    private func setupSampleData() {
        // Sadece meetingTypes için sample data, diğerleri Firebase'den yüklenecek
        if meetingTypes.isEmpty {
            meetingTypes = [
                MeetingType(name: "30 Dakika - Genel Görüşme", duration: 30, platform: .googleMeet, description: "Kısa ve verimli görüşmeler için"),
                MeetingType(name: "60 Dakika - Detaylı Görüşme", duration: 60, platform: .googleMeet, description: "Uzun ve detaylı tartışmalar için"),
                MeetingType(name: "Danışmanlık", duration: 45, platform: .zoom, description: "Profesyonel danışmanlık hizmetleri")
            ]
        }
        
        // Sample contacts - bu da Firebase'den yüklenebilir
        if contacts.isEmpty {
            contacts = [
                Contact(name: "Ahmet Yılmaz", email: "ahmet@example.com", meetingCount: 5),
                Contact(name: "Zeynep Kaya", email: "zeynep@example.com", meetingCount: 3),
                Contact(name: "Mehmet Demir", email: "mehmet@example.com", meetingCount: 2)
            ]
        }
    }
    
    // MARK: - Meeting Management
    
    func addMeeting(_ meeting: Meeting) {
        // Önce local'e ekle
        meetings.append(meeting)
        updateContactsFromMeetings()
        
        // Sonra Firebase'e kaydet
        FirebaseDataManager.shared.saveMeeting(meeting) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ ViewModel: Toplantı Firebase'e kaydedildi: \(meeting.title)")
                } else {
                    print("❌ ViewModel: Toplantı kaydetme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    // Hata durumunda local'den kaldır
                    self.meetings.removeAll { $0.id == meeting.id }
                    self.updateContactsFromMeetings()
                }
            }
        }
    }
    
    func addMeetingType(_ meetingType: MeetingType) {
        // Önce local'e ekle
        meetingTypes.append(meetingType)
        
        // Sonra Firebase'e kaydet
        FirebaseDataManager.shared.saveMeetingType(meetingType) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ ViewModel: Toplantı türü Firebase'e kaydedildi: \(meetingType.name)")
                } else {
                    print("❌ ViewModel: Toplantı türü kaydetme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    // Hata durumunda local'den kaldır
                    self.meetingTypes.removeAll { $0.id == meetingType.id }
                }
            }
        }
    }
    
    // MARK: - Availability Management
    
    func updateAvailability(_ newAvailability: Availability) {
        // Önce local'i güncelle
        availability = newAvailability
        print("✅ ViewModel: Local müsaitlik ayarları güncellendi")
        
        // Firebase'e kaydetme işlemi FirebaseDataManager'da yapılacak
        // Bu fonksiyon sadece local state'i güncellemek için kullanılıyor
    }
    
    func refreshAvailabilityFromFirebase() {
        loadAvailabilityFromFirebase()
    }
    
    // MARK: - Contact Management
    
    private func updateContactsFromMeetings() {
        // Toplantılardan kişi listesini güncelle
        var updatedContacts: [Contact] = []
        
        for meeting in meetings {
            if let existingContactIndex = updatedContacts.firstIndex(where: { $0.email == meeting.participantEmail }) {
                updatedContacts[existingContactIndex].meetingCount += 1
            } else {
                // Yeni kişi ekle
                let name = extractNameFromEmail(meeting.participantEmail)
                let newContact = Contact(name: name, email: meeting.participantEmail, meetingCount: 1)
                updatedContacts.append(newContact)
            }
        }
        
        // Mevcut sample contacts'ı koru ama toplantı sayılarını güncelle
        for existingContact in contacts {
            if !updatedContacts.contains(where: { $0.email == existingContact.email }) {
                updatedContacts.append(existingContact)
            }
        }
        
        contacts = updatedContacts
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let namePart = email.components(separatedBy: "@").first ?? "Unknown"
        return namePart.capitalized
    }
    
    // MARK: - Statistics
    
    var monthlyStats: (meetings: Int, contacts: Int, hoursSaved: Int) {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthlyMeetings = meetings.filter {
            Calendar.current.component(.month, from: $0.date) == currentMonth
        }.count
        
        return (
            meetings: monthlyMeetings,
            contacts: contacts.count,
            hoursSaved: monthlyMeetings * 2
        )
    }
    
    // MARK: - Data Refresh
    
    func refreshAllData() {
        print("🔄 ViewModel: Tüm veriler yenileniyor...")
        loadDataFromFirebase()
    }
    
    // MARK: - Availability Helper Methods
    
    var availabilityStatusText: String {
        if isLoadingAvailability {
            return "Müsaitlik ayarları yükleniyor..."
        }
        
        let dayCount = availability.workDays.count
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        return "\(dayCount) gün, \(timeFormatter.string(from: availability.startTime)) - \(timeFormatter.string(from: availability.endTime))"
    }
    
    func isTimeSlotAvailable(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Weekday'i WeekDay enum'a çevir (Calendar.Component.weekday 1=Sunday, 2=Monday vs.)
        let availableWeekdays: Set<Int> = Set(availability.workDays.compactMap { weekDay in
            switch weekDay {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        })
        
        guard availableWeekdays.contains(weekday) else {
            return false
        }
        
        // Saat kontrolü
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let startComponents = calendar.dateComponents([.hour, .minute], from: availability.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: availability.endTime)
        
        guard let hour = timeComponents.hour,
              let minute = timeComponents.minute,
              let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return false
        }
        
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
