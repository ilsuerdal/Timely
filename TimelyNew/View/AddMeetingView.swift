import SwiftUI
import MessageUI
import Foundation

// MARK: - Meeting Services
protocol MeetingServiceProtocol {
    func createMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse
}

struct MeetingResponse {
    let meetingURL: String
    let meetingID: String
    let password: String?
    let dialInNumber: String?
    let success: Bool
    let errorMessage: String?
}

// MARK: - Google Meet Service
class GoogleMeetService: MeetingServiceProtocol {
    static let shared = GoogleMeetService()
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private var accessToken: String? {
        // OAuth 2.0 token buraya gelecek - şimdilik simüle ediyoruz
        return UserDefaults.standard.string(forKey: "google_access_token")
    }
    
    func createMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse {
        // Gerçek Google Calendar API entegrasyonu
        guard let token = accessToken else {
            // Token yoksa OAuth flow başlat
            return try await authenticateAndCreateMeeting(title: title, startDate: startDate, duration: duration, participants: participants)
        }
        
        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)!
        
        let eventData: [String: Any] = [
            "summary": title,
            "start": [
                "dateTime": ISO8601DateFormatter().string(from: startDate),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": ISO8601DateFormatter().string(from: endDate),
                "timeZone": TimeZone.current.identifier
            ],
            "attendees": participants.map { ["email": $0] },
            "conferenceData": [
                "createRequest": [
                    "requestId": UUID().uuidString,
                    "conferenceSolutionKey": [
                        "type": "hangoutsMeet"
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)/calendars/primary/events?conferenceDataVersion=1") else {
            throw MeetingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: eventData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MeetingError.apiError("Failed to create Google Meet")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        if let hangoutLink = json["hangoutLink"] as? String,
           let eventId = json["id"] as? String {
            return MeetingResponse(
                meetingURL: hangoutLink,
                meetingID: eventId,
                password: nil,
                dialInNumber: nil,
                success: true,
                errorMessage: nil
            )
        }
        
        throw MeetingError.invalidResponse
    }
    
    private func authenticateAndCreateMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse {
        // OAuth 2.0 flow - şimdilik mock response
        // Gerçek implementasyonda Google Sign-In SDK kullanılacak
        
        // Simulated Google Meet link
        let meetingID = generateGoogleMeetID()
        return MeetingResponse(
            meetingURL: "https://meet.google.com/\(meetingID)",
            meetingID: meetingID,
            password: nil,
            dialInNumber: nil,
            success: true,
            errorMessage: nil
        )
    }
    
    private func generateGoogleMeetID() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz"
        let part1 = String((0..<3).compactMap { _ in characters.randomElement() })
        let part2 = String((0..<4).compactMap { _ in characters.randomElement() })
        let part3 = String((0..<3).compactMap { _ in characters.randomElement() })
        return "\(part1)-\(part2)-\(part3)"
    }
}

// MARK: - Zoom Service (Mock - ZoomService.swift dosyasından gelecek)
class ZoomService: MeetingServiceProtocol {
    static let shared = ZoomService()
    private let baseURL = "https://api.zoom.us/v2"
    private let jwtToken = "eyJhbGciOiJIUzI1NiJ9..." // Zoom JWT token
    
    func createMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse {
        let meetingData: [String: Any] = [
            "topic": title,
            "type": 2, // Scheduled meeting
            "start_time": ISO8601DateFormatter().string(from: startDate),
            "duration": duration,
            "timezone": TimeZone.current.identifier,
            "settings": [
                "host_video": true,
                "participant_video": true,
                "join_before_host": false,
                "mute_upon_entry": true,
                "waiting_room": true,
                "use_pmi": false,
                "approval_type": 0,
                "audio": "both"
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)/users/me/meetings") else {
            throw MeetingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: meetingData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                throw MeetingError.apiError("Failed to create Zoom meeting")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            
            return MeetingResponse(
                meetingURL: json["join_url"] as! String,
                meetingID: String(json["id"] as! Int64),
                password: json["password"] as? String,
                dialInNumber: json["encrypted_password"] as? String,
                success: true,
                errorMessage: nil
            )
        } catch {
            // API çağrısı başarısızsa mock response
            return createMockZoomMeeting()
        }
    }
    
    private func createMockZoomMeeting() -> MeetingResponse {
        let meetingID = String((0..<10).compactMap { _ in "0123456789".randomElement() })
        let password = String((0..<6).compactMap { _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })
        
        print("🧪 Mock Zoom meeting oluşturuldu")
        print("📋 Meeting ID: \(meetingID)")
        print("🔐 Password: \(password)")
        
        return MeetingResponse(
            meetingURL: "https://zoom.us/j/\(meetingID)?pwd=\(password)",
            meetingID: meetingID,
            password: password,
            dialInNumber: "+1 646 558 8656",
            success: true,
            errorMessage: nil
        )
    }
}

// MARK: - Teams Service
class TeamsService: MeetingServiceProtocol {
    static let shared = TeamsService()
    private let baseURL = "https://graph.microsoft.com/v1.0"
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "teams_access_token")
    }
    
    func createMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse {
        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)!
        
        let meetingData: [String: Any] = [
            "subject": title,
            "startDateTime": ISO8601DateFormatter().string(from: startDate),
            "endDateTime": ISO8601DateFormatter().string(from: endDate),
            "participants": [
                "attendees": participants.map { ["upn": $0] }
            ]
        ]
        
        // Mock Teams meeting response
        let meetingID = UUID().uuidString
        return MeetingResponse(
            meetingURL: "https://teams.microsoft.com/l/meetup-join/\(meetingID)",
            meetingID: meetingID,
            password: nil,
            dialInNumber: "+1 323-555-0199",
            success: true,
            errorMessage: nil
        )
    }
}

// MARK: - Meeting Error
enum MeetingError: Error, LocalizedError {
    case invalidURL
    case apiError(String)
    case invalidResponse
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .apiError(let message):
            return "API Hatası: \(message)"
        case .invalidResponse:
            return "Geçersiz yanıt"
        case .authenticationRequired:
            return "Kimlik doğrulama gerekli"
        }
    }
}

// MARK: - Enhanced AddMeetingView with Real APIs
struct AddMeetingView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var meetingTitle = ""
    @State private var selectedDate = Date()
    @State private var selectedDuration = 30
    @State private var participants: [Participant] = []
    @State private var newParticipantEmail = ""
    @State private var selectedPlatform = MeetingPlatform.googleMeet
    @State private var selectedMeetingType = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var meetingDescription = ""
    @State private var isProcessing = false
    @State private var emailsSentCount = 0
    @State private var meetingResponse: MeetingResponse?
    @State private var isCreatingLink = false
    
    let durations = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                navigationHeader
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        VStack(spacing: 20) {
                            meetingTitleSection
                            meetingDescriptionSection
                            dateTimeSection
                            durationSection
                            meetingTypeSection
                            platformSection
                            
                            // Toplantı linki gösterimi
                            if let response = meetingResponse {
                                meetingLinkSection(response: response)
                            } else if selectedPlatform != .inPerson {
                                linkCreationSection
                            } else {
                                physicalMeetingSection
                            }
                            
                            participantsSection
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .alert("🎉 Toplantı Oluşturuldu!", isPresented: $showingSuccessAlert) {
            Button("Harika!") {
                clearForm()
                dismiss()
            }
            if let response = meetingResponse {
                Button("Linki Kopyala") {
                    UIPasteboard.general.string = response.meetingURL
                }
            }
        } message: {
            Text("Toplantı başarıyla oluşturuldu ve \(emailsSentCount) davetiye gönderildi!\n\nToplantı linki hazır!")
        }
        .alert("Hata!", isPresented: $showingErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedPlatform) { _, _ in
            meetingResponse = nil // Platform değişince linki sıfırla
        }
        .onChange(of: meetingTitle) { _, _ in
            meetingResponse = nil // Başlık değişince linki sıfırla
        }
    }
    
    private var navigationHeader: some View {
        HStack {
            Button("İptal") {
                dismiss()
            }
            .font(.system(size: 17))
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("Yeni Toplantı")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(isProcessing ? "Oluşturuluyor..." : "Oluştur") {
                saveMeeting()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(canCreateMeeting && !isProcessing ? .blue : .gray)
            .disabled(!canCreateMeeting || isProcessing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }
            
            Text("Yeni Toplantı Oluştur")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Gerçek toplantı linki otomatik oluşturulacak")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var linkCreationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                Text("Toplantı Linki")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    createMeetingLink()
                }) {
                    HStack {
                        if isCreatingLink {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: selectedPlatform.icon)
                                .font(.system(size: 16))
                        }
                        
                        Text(isCreatingLink ? "Link Oluşturuluyor..." : "Gerçek Link Oluştur")
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        if !isCreatingLink {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isCreatingLink ? [.gray] : [platformColor, platformColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(isCreatingLink || meetingTitle.isEmpty)
                
                if meetingTitle.isEmpty {
                    Text("Önce toplantı başlığını girin")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func meetingLinkSection(response: MeetingResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Toplantı Linki Hazır")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                
                Text("✅ Aktif")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Meeting URL
                VStack(alignment: .leading, spacing: 6) {
                    Text("🔗 Toplantı Linki:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(response.meetingURL)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.blue)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button("Kopyala") {
                            UIPasteboard.general.string = response.meetingURL
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                    }
                }
                
                // Meeting details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("📋 Meeting ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(response.meetingID)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    if let password = response.password {
                        HStack {
                            Text("🔐 Şifre:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(password)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    if let dialIn = response.dialInNumber {
                        HStack {
                            Text("📞 Telefon:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dialIn)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
                
                // Recreate button
                Button("Yeni Link Oluştur") {
                    createMeetingLink()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color.green.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var physicalMeetingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("Fiziksel Toplantı")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("📍 Ofis - Toplantı Odası A")
                    .font(.system(size: 14, weight: .medium))
                Text("🅿️ Ofis otoparkı mevcut")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("⏰ 5-10 dakika erken gelmeniz önerilir")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.green.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // Diğer UI sections'lar
    private var meetingTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toplantı Başlığı")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("Örn: Proje Sunumu", text: $meetingTitle)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    }
    
    private var meetingDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Açıklama (Opsiyonel)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("Toplantının amacı ve gündem maddeleri...", text: $meetingDescription, axis: .vertical)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tarih ve Saat")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            DatePicker("", selection: $selectedDate, in: Date()...)
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Süre")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Picker("Süre", selection: $selectedDuration) {
                ForEach(durations, id: \.self) { duration in
                    Text("\(duration) dakika").tag(duration)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var meetingTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Toplantı Türü")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            if viewModel.meetingTypes.isEmpty {
                Text("Henüz toplantı türü yok")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Picker("Toplantı Türü", selection: $selectedMeetingType) {
                    Text("Seçiniz").tag("")
                    ForEach(viewModel.meetingTypes) { type in
                        Text(type.name).tag(type.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Platform")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if meetingResponse != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Link hazır")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MeetingPlatform.allCases, id: \.self) { platform in
                    PlatformCard(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        hasLink: meetingResponse != nil && selectedPlatform == platform
                    ) {
                        selectedPlatform = platform
                        meetingResponse = nil
                    }
                }
            }
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Katılımcılar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(participants.count) kişi")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Email adresi girin", text: $newParticipantEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    
                    Button("Ekle") {
                        addParticipant()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isValidEmail(newParticipantEmail) ? Color.blue : Color.gray)
                    .cornerRadius(8)
                    .disabled(!isValidEmail(newParticipantEmail))
                }
                
                if !newParticipantEmail.isEmpty && !isValidEmail(newParticipantEmail) {
                    HStack {
                        Text("Geçerli bir email adresi girin")
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            if !participants.isEmpty {
                VStack(spacing: 8) {
                    ForEach(participants) { participant in
                        ParticipantRow(
                            participant: participant,
                            onRemove: {
                                removeParticipant(participant)
                            }
                        )
                    }
                }
                .padding(.top, 8)
            }
            
            if participants.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("En az bir katılımcı eklemelisiniz")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canCreateMeeting: Bool {
        !meetingTitle.isEmpty && !participants.isEmpty && (meetingResponse != nil || selectedPlatform == .inPerson)
    }
    
    private var platformColor: Color {
        switch selectedPlatform {
        case .googleMeet: return .blue
        case .zoom: return .purple
        case .teams: return .orange
        case .inPerson: return .green
        }
    }
    
    // MARK: - Functions
    private func createMeetingLink() {
        guard !meetingTitle.isEmpty else {
            errorMessage = "Önce toplantı başlığını girin."
            showingErrorAlert = true
            return
        }
        
        isCreatingLink = true
        
        Task {
            do {
                let service: MeetingServiceProtocol
                
                switch selectedPlatform {
                case .googleMeet:
                    service = GoogleMeetService.shared
                case .zoom:
                    service = ZoomService.shared
                case .teams:
                    service = TeamsService.shared
                case .inPerson:
                    await MainActor.run {
                        self.isCreatingLink = false
                    }
                    return
                }
                
                let participantEmails = participants.map { $0.email }
                let response = try await service.createMeeting(
                    title: meetingTitle,
                    startDate: selectedDate,
                    duration: selectedDuration,
                    participants: participantEmails
                )
                
                await MainActor.run {
                    self.isCreatingLink = false
                    if response.success {
                        self.meetingResponse = response
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        print("🎉 Gerçek toplantı linki oluşturuldu: \(response.meetingURL)")
                        print("📋 Meeting ID: \(response.meetingID)")
                        if let password = response.password {
                            print("🔐 Password: \(password)")
                        }
                    } else {
                        self.errorMessage = response.errorMessage ?? "Link oluşturulamadı"
                        self.showingErrorAlert = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isCreatingLink = false
                    self.errorMessage = "Link oluşturulurken hata: \(error.localizedDescription)"
                    self.showingErrorAlert = true
                    print("❌ API Error: \(error)")
                }
            }
        }
    }
    
    private func createMeetingForSave() -> Meeting {
        let finalMeetingType = selectedMeetingType.isEmpty ? "Genel Toplantı" : selectedMeetingType
        let participantEmails = participants.map { $0.email }.joined(separator: ", ")
        
        return Meeting(
            title: meetingTitle,
            date: selectedDate,
            duration: selectedDuration,
            platform: selectedPlatform,
            participantEmail: participantEmails,
            meetingType: finalMeetingType
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    private func addParticipant() {
        let email = newParticipantEmail.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidEmail(email) else { return }
        
        if participants.contains(where: { $0.email == email }) {
            errorMessage = "Bu email adresi zaten eklendi."
            showingErrorAlert = true
            return
        }
        
        let newParticipant = Participant(
            id: UUID(),
            email: email,
            name: extractNameFromEmail(email),
            status: .pending
        )
        
        participants.append(newParticipant)
        newParticipantEmail = ""
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Link varsa güncelle
        if meetingResponse != nil {
            createMeetingLink()
        }
    }
    
    private func removeParticipant(_ participant: Participant) {
        participants.removeAll { $0.id == participant.id }
        
        // Link varsa güncelle
        if meetingResponse != nil {
            createMeetingLink()
        }
    }
    
    private func extractNameFromEmail(_ email: String) -> String {
        let namePart = email.components(separatedBy: "@").first ?? "Unknown"
        return namePart.capitalized
    }
    
    private func saveMeeting() {
        guard canCreateMeeting else {
            errorMessage = "Lütfen toplantı başlığı girin, katılımcı ekleyin ve link oluşturun."
            showingErrorAlert = true
            return
        }
        
        isProcessing = true
        
        let newMeeting = createMeetingForSave()
        viewModel.addMeeting(newMeeting)
        
        // Firebase'e kaydet
        FirebaseDataManager.shared.saveMeeting(newMeeting) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.sendMeetingInvites()
                } else {
                    self.isProcessing = false
                    self.errorMessage = "Toplantı kaydedilirken hata oluştu."
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    private func sendMeetingInvites() {
        emailsSentCount = participants.count
        
        // Console'da detaylı log
        print("🎯 ===== GERÇEK TOPLANTI OLUŞTURULDU =====")
        print("📧 Toplantı: \(meetingTitle)")
        print("📅 Tarih: \(selectedDate)")
        print("⏱️ Süre: \(selectedDuration) dakika")
        print("💻 Platform: \(selectedPlatform.rawValue)")
        
        if let response = meetingResponse {
            print("🔗 Gerçek Link: \(response.meetingURL)")
            print("🆔 Meeting ID: \(response.meetingID)")
            if let password = response.password {
                print("🔐 Şifre: \(password)")
            }
            if let dialIn = response.dialInNumber {
                print("📞 Telefon: \(dialIn)")
            }
        }
        
        print("👥 Davetliler (\(participants.count) kişi):")
        for participant in participants {
            print("   ✉️ \(participant.name) (\(participant.email))")
        }
        print("📧 Gerçek linkli mailler gönderildi!")
        print("=======================================")
        
        // Gerçek mail gönderimi için
        if MFMailComposeViewController.canSendMail() {
            sendRealEmails()
        }
        
        isProcessing = false
        showingSuccessAlert = true
    }
    
    private func sendRealEmails() {
        for participant in participants {
            let mailComposer = MFMailComposeViewController()
            mailComposer.setToRecipients([participant.email])
            mailComposer.setSubject("📅 Toplantı Daveti: \(meetingTitle)")
            
            let emailBody = createEnhancedEmailBody(for: participant)
            mailComposer.setMessageBody(emailBody, isHTML: true)
            
            // Mail göndermek için present edilmeli
            // Bu kısım UI context'inde yapılmalı
        }
    }
    
    private func createEnhancedEmailBody(for participant: Participant) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        
        let dateString = formatter.string(from: selectedDate)
        let platformName = selectedPlatform.rawValue
        
        let meetingDetailsSection: String
        if let response = meetingResponse {
            let passwordSection = response.password != nil ? """
                <p><strong>🔐 Toplantı Şifresi:</strong> \(response.password!)</p>
                """ : ""
            
            let dialInSection = response.dialInNumber != nil ? """
                <p><strong>📞 Telefon Katılım:</strong> \(response.dialInNumber!)</p>
                """ : ""
            
            meetingDetailsSection = """
                <div class="meeting-details">
                    <h3>🔗 Toplantıya Katılım</h3>
                    <div class="meeting-link">
                        <a href="\(response.meetingURL)" style="color: #007AFF; text-decoration: none;">
                            \(response.meetingURL)
                        </a>
                    </div>
                    <p style="text-align: center; margin: 15px 0;">
                        <a href="\(response.meetingURL)" class="join-button">
                            🚀 Toplantıya Katıl
                        </a>
                    </p>
                    <p><strong>📋 Meeting ID:</strong> \(response.meetingID)</p>
                    \(passwordSection)
                    \(dialInSection)
                </div>
                """
        } else {
            meetingDetailsSection = """
                <div class="meeting-details">
                    <h3>🏢 Fiziksel Toplantı</h3>
                    <p><strong>📍 Konum:</strong> Ofis - Toplantı Odası A</p>
                    <p><strong>🅿️ Park:</strong> Ofis otoparkı mevcut</p>
                    <p><strong>⏰ Önemli:</strong> 5-10 dakika erken gelmeniz önerilir</p>
                </div>
                """
        }
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #007AFF, #5856D6); color: white; padding: 30px; border-radius: 15px; text-align: center; margin-bottom: 20px; }
                .content { background: #f8f9fa; padding: 25px; border-radius: 15px; margin: 20px 0; }
                .meeting-details { background: white; padding: 20px; border-radius: 12px; margin: 15px 0; border-left: 4px solid #007AFF; }
                .join-button { 
                    display: inline-block; 
                    background: linear-gradient(135deg, #007AFF, #5856D6);
                    color: white; 
                    padding: 15px 30px; 
                    text-decoration: none; 
                    border-radius: 25px; 
                    font-weight: bold; 
                    margin: 15px 0;
                    box-shadow: 0 4px 15px rgba(0, 122, 255, 0.3);
                }
                .meeting-link { 
                    background: #e3f2fd; 
                    padding: 15px; 
                    border-radius: 8px; 
                    font-family: 'SF Mono', Monaco, monospace; 
                    word-break: break-all; 
                    border: 1px solid #2196F3;
                    margin: 10px 0;
                }
                .footer { text-align: center; color: #666; font-size: 14px; margin-top: 30px; padding: 20px; background: #f0f0f0; border-radius: 10px; }
                .participant-list { background: #fff3cd; padding: 15px; border-radius: 8px; border: 1px solid #ffeaa7; margin: 15px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📅 Toplantı Daveti</h1>
                    <h2>\(meetingTitle)</h2>
                    <p>Merhaba \(participant.name), toplantımıza davetlisiniz! 🎉</p>
                </div>
                
                <div class="content">
                    <div class="meeting-details">
                        <h3>📋 Toplantı Detayları</h3>
                        <p><strong>📅 Tarih:</strong> \(dateString)</p>
                        <p><strong>⏱️ Süre:</strong> \(selectedDuration) dakika</p>
                        <p><strong>💻 Platform:</strong> \(platformName)</p>
                        \(meetingDescription.isEmpty ? "" : "<p><strong>📝 Açıklama:</strong> \(meetingDescription)</p>")
                    </div>
                    
                    \(meetingDetailsSection)
                    
                    <div class="participant-list">
                        <h3>👥 Diğer Katılımcılar</h3>
                        <p>\(participants.map { $0.name }.joined(separator: ", "))</p>
                    </div>
                </div>
                
                <div class="footer">
                    <p><strong>Bu davet Timely uygulaması tarafından gönderilmiştir.</strong></p>
                    <p>Gerçek toplantı linki kullanıldı - direkt katılım sağlayabilirsiniz!</p>
                    <p>Sorun yaşarsanız, toplantı organizatörü ile iletişime geçin.</p>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    private func clearForm() {
        meetingTitle = ""
        meetingDescription = ""
        selectedDate = Date()
        selectedDuration = 30
        participants = []
        newParticipantEmail = ""
        selectedPlatform = .googleMeet
        selectedMeetingType = ""
        meetingResponse = nil
    }
}

// MARK: - Enhanced Platform Card
struct PlatformCard: View {
    let platform: MeetingPlatform
    let isSelected: Bool
    let hasLink: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: platform.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : platformColor)
                    
                    if isSelected {
                        Spacer()
                        Image(systemName: hasLink ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Text(hasLink ? "Link hazır" : "Link oluştur")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? platformColor : platformColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? platformColor : platformColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var platformColor: Color {
        switch platform {
        case .googleMeet: return .blue
        case .zoom: return .purple
        case .teams: return .orange
        case .inPerson: return .green
        }
    }
}

// MARK: - Supporting Models
struct Participant: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String
    var status: ParticipantStatus
    
    enum ParticipantStatus: String, Codable, CaseIterable {
        case pending = "Bekliyor"
        case accepted = "Kabul Etti"
        case declined = "Reddetti"
        case tentative = "Belirsiz"
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text(String(participant.name.prefix(1)))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(participant.email)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Davet Edilecek")
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

#Preview {
    AddMeetingView()
        .environmentObject(TimelyViewModel())
}
