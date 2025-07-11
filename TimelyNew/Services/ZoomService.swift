//
//  ZoomService.swift
//  TimelyNew
//
//  Created by ilsu on 21.06.2025.
//

import Foundation

// MARK: - Zoom Configuration
struct ZoomConfig {
    // Zoom App Credentials (marketplace.zoom.us'dan alacağınız)
    static let accountID = "gRbCnW9YQMyv9uSnVuthVQ "      // Zoom Account ID
    static let clientID = "qQVk1o2aRj9_GXqrWkl2w"        // Zoom Client ID
    static let clientSecret = "LY3ZuVHmG8dbu5nzinp47LI3RNvT1Gc3" // Zoom Client Secret
    static let baseURL = "https://api.zoom.us/v2"
}

// MARK: - Zoom Authentication Service
class ZoomAuthService {
    static let shared = ZoomAuthService()
    private var accessToken: String?
    private var tokenExpiryDate: Date?
    
    func getAccessToken() async throws -> String {
        // Token hala geçerliyse mevcut token'ı döndür
        if let token = accessToken,
           let expiry = tokenExpiryDate,
           expiry > Date().addingTimeInterval(300) { // 5 dakika buffer
            return token
        }
        
        // Yeni token al
        return try await refreshAccessToken()
    }
    
    private func refreshAccessToken() async throws -> String {
        let tokenURL = "https://zoom.us/oauth/token"
        let credentials = "\(ZoomConfig.clientID):\(ZoomConfig.clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=account_credentials&account_id=\(ZoomConfig.accountID)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ZoomError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(ZoomTokenResponse.self, from: data)
        
        self.accessToken = tokenResponse.access_token
        self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        
        print("✅ Zoom access token alındı: \(tokenResponse.access_token.prefix(20))...")
        
        return tokenResponse.access_token
    }
}

// MARK: - Zoom Token Response
struct ZoomTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String
}

// MARK: - Gerçek Zoom Service
class RealZoomService: MeetingServiceProtocol {
    static let shared = RealZoomService()
    
    func createMeeting(title: String, startDate: Date, duration: Int, participants: [String]) async throws -> MeetingResponse {
        // 1. Access token al
        let accessToken = try await ZoomAuthService.shared.getAccessToken()
        
        // 2. Meeting oluştur
        let meetingData = ZoomMeetingRequest(
            topic: title,
            type: 2, // Scheduled meeting
            start_time: ISO8601DateFormatter().string(from: startDate),
            duration: duration,
            timezone: TimeZone.current.identifier,
            settings: ZoomMeetingSettings(
                host_video: true,
                participant_video: true,
                join_before_host: false,
                mute_upon_entry: true,
                waiting_room: true,
                use_pmi: false,
                approval_type: 0,
                audio: "both",
                auto_recording: "none"
            )
        )
        
        // 3. API çağrısı yap
        guard let url = URL(string: "\(ZoomConfig.baseURL)/users/me/meetings") else {
            throw ZoomError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(meetingData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ZoomError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            // Başarılı - gerçek meeting response
            let zoomMeeting = try JSONDecoder().decode(ZoomMeetingCreateResponse.self, from: data)
            
            print("🎉 Gerçek Zoom toplantısı oluşturuldu!")
            print("📋 Meeting ID: \(zoomMeeting.id)")
            print("🔗 Join URL: \(zoomMeeting.join_url)")
            print("🔐 Password: \(zoomMeeting.password)")
            
            return MeetingResponse(
                meetingURL: zoomMeeting.join_url,
                meetingID: String(zoomMeeting.id),
                password: zoomMeeting.password,
                dialInNumber: extractDialInNumber(from: zoomMeeting),
                success: true,
                errorMessage: nil
            )
        } else {
            // Hata durumu
            let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Bilinmeyen hata"
            
            print("❌ Zoom API hatası: \(httpResponse.statusCode)")
            print("📄 Error: \(errorMessage)")
            
            throw ZoomError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
    }
    
    private func extractDialInNumber(from meeting: ZoomMeetingCreateResponse) -> String? {
        // Zoom genelde US dial-in number verir
        return "+1 669 900 9128" // Zoom'un genel dial-in numarası
    }
}

// MARK: - Zoom Data Models
struct ZoomMeetingRequest: Codable {
    let topic: String
    let type: Int
    let start_time: String
    let duration: Int
    let timezone: String
    let settings: ZoomMeetingSettings
}

struct ZoomMeetingSettings: Codable {
    let host_video: Bool
    let participant_video: Bool
    let join_before_host: Bool
    let mute_upon_entry: Bool
    let waiting_room: Bool
    let use_pmi: Bool
    let approval_type: Int
    let audio: String
    let auto_recording: String
}

struct ZoomMeetingCreateResponse: Codable {
    let id: Int64
    let topic: String
    let type: Int
    let start_time: String
    let duration: Int
    let timezone: String
    let join_url: String
    let password: String
    let start_url: String
    let uuid: String
}

// MARK: - Zoom Errors
enum ZoomError: Error, LocalizedError {
    case invalidURL
    case authenticationFailed
    case apiError(String)
    case invalidResponse
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz Zoom API URL"
        case .authenticationFailed:
            return "Zoom kimlik doğrulama başarısız"
        case .apiError(let message):
            return "Zoom API Hatası: \(message)"
        case .invalidResponse:
            return "Zoom'dan geçersiz yanıt"
        case .invalidCredentials:
            return "Zoom API credentials hatalı"
        }
    }
}

