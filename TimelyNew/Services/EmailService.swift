//
//  EmailService.swift
//  TimelyNew
//
//  Created by ilsu on 20.06.2025.
//

import Foundation
import MessageUI
import UIKit

// MARK: - Email Service
class EmailService: NSObject, ObservableObject {
    static let shared = EmailService()
    
    @Published var isEmailComposerPresented = false
    @Published var emailResult: Result<MFMailComposeResult, Error>?
    
    private override init() {}
    
    // MARK: - Email Availability Check
    func canSendEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    // MARK: - Send Meeting Invitation
    func sendMeetingInvitation(
        to email: String,
        meeting: Meeting,
        organizerName: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        // iOS native email ile gönder
        if canSendEmail() {
            sendViaMailComposer(
                to: email,
                meeting: meeting,
                organizerName: organizerName,
                completion: completion
            )
        } else {
            // Fallback: External email service API
            sendViaExternalService(
                to: email,
                meeting: meeting,
                organizerName: organizerName,
                completion: completion
            )
        }
    }
    
    // MARK: - Mail Composer Method
    private func sendViaMailComposer(
        to email: String,
        meeting: Meeting,
        organizerName: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                completion(false, "Pencere bulunamadı")
                return
            }
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            // Email content
            let emailContent = self.createEmailContent(meeting: meeting, organizerName: organizerName)
            
            mailComposer.setToRecipients([email])
            mailComposer.setSubject(emailContent.subject)
            mailComposer.setMessageBody(emailContent.body, isHTML: true)
            
            // ICS calendar attachment
            if let icsData = self.createICSCalendarEvent(meeting: meeting, organizerName: organizerName) {
                mailComposer.addAttachmentData(icsData, mimeType: "text/calendar", fileName: "meeting.ics")
            }
            
            // Present mail composer
            rootViewController.present(mailComposer, animated: true)
            
            completion(true, "Email composer açıldı")
        }
    }
    
    // MARK: - External Service Method (Backup)
    private func sendViaExternalService(
        to email: String,
        meeting: Meeting,
        organizerName: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        // EmailJS, SendGrid, veya başka bir service kullanılabilir
        // Şimdilik basit bir HTTP request örneği
        
        let emailContent = createEmailContent(meeting: meeting, organizerName: organizerName)
        
        // Örnek API endpoint (gerçek service ile değiştirin)
        guard let url = URL(string: "https://api.emailjs.com/api/v1.0/email/send") else {
            completion(false, "Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emailData: [String: Any] = [
            "service_id": "your_service_id", // EmailJS service ID
            "template_id": "your_template_id", // EmailJS template ID
            "user_id": "your_user_id", // EmailJS user ID
            "template_params": [
                "to_email": email,
                "subject": emailContent.subject,
                "message": emailContent.body,
                "organizer_name": organizerName
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
        } catch {
            completion(false, "JSON encoding hatası: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network hatası: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, "Email başarıyla gönderildi!")
                    } else {
                        completion(false, "Email gönderim hatası: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "Geçersiz response")
                }
            }
        }.resume()
    }
    
    // MARK: - Create Email Content
    private func createEmailContent(meeting: Meeting, organizerName: String) -> (subject: String, body: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "tr_TR")
        
        let subject = "📅 Toplantı Davetiyesi: \(meeting.title)"
        
        let body = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; padding: 20px; background-color: #f5f5f7; }
                .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
                .content { padding: 30px; }
                .meeting-details { background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; }
                .detail-row { display: flex; margin: 10px 0; align-items: center; }
                .detail-icon { margin-right: 10px; }
                .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 14px; color: #666; }
                .button { display: inline-block; background: #007AFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; margin: 20px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>📅 Toplantı Davetiyesi</h1>
                    <p>Yeni bir toplantıya davet edildiniz</p>
                </div>
                
                <div class="content">
                    <h2>Merhaba!</h2>
                    <p><strong>\(organizerName)</strong> sizi bir toplantıya davet ediyor.</p>
                    
                    <div class="meeting-details">
                        <h3>\(meeting.title)</h3>
                        
                        <div class="detail-row">
                            <span class="detail-icon">📅</span>
                            <strong>Tarih:</strong> \(dateFormatter.string(from: meeting.date))
                        </div>
                        
                        <div class="detail-row">
                            <span class="detail-icon">⏱️</span>
                            <strong>Süre:</strong> \(meeting.duration) dakika
                        </div>
                        
                        <div class="detail-row">
                            <span class="detail-icon">💻</span>
                            <strong>Platform:</strong> \(meeting.platform.rawValue)
                        </div>
                        
                        <div class="detail-row">
                            <span class="detail-icon">🏷️</span>
                            <strong>Toplantı Türü:</strong> \(meeting.meetingType)
                        </div>
                    </div>
                    
                    <div style="text-align: center;">
                        <a href="#" class="button">📅 Takvime Ekle</a>
                    </div>
                    
                    <p><strong>📝 Not:</strong> Bu toplantı Timely uygulaması ile organize edilmiştir.</p>
                </div>
                
                <div class="footer">
                    <p>Bu email Timely - Akıllı Toplantı Planlayıcısı tarafından gönderilmiştir.</p>
                    <p>Sorularınız için lütfen \(organizerName) ile iletişime geçin.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return (subject, body)
    }
    
    // MARK: - Create ICS Calendar Event
    private func createICSCalendarEvent(meeting: Meeting, organizerName: String) -> Data? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startDate = dateFormatter.string(from: meeting.date)
        let endDate = dateFormatter.string(from: meeting.date.addingTimeInterval(TimeInterval(meeting.duration * 60)))
        let now = dateFormatter.string(from: Date())
        
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Timely//Timely App//EN
        CALSCALE:GREGORIAN
        METHOD:REQUEST
        BEGIN:VEVENT
        UID:\(meeting.id)@timely.app
        DTSTAMP:\(now)
        ORGANIZER:CN=\(organizerName)
        DTSTART:\(startDate)
        DTEND:\(endDate)
        SUMMARY:\(meeting.title)
        DESCRIPTION:Toplantı Türü: \(meeting.meetingType)\\nPlatform: \(meeting.platform.rawValue)\\nOrganizatör: \(organizerName)
        LOCATION:\(meeting.platform.rawValue)
        STATUS:CONFIRMED
        SEQUENCE:0
        END:VEVENT
        END:VCALENDAR
        """
        
        return icsContent.data(using: .utf8)
    }
}

// MARK: - Mail Compose Delegate
extension EmailService: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DispatchQueue.main.async {
            self.emailResult = .success(result)
            controller.dismiss(animated: true)
            
            switch result {
            case .sent:
                print("✅ Email başarıyla gönderildi")
            case .saved:
                print("📝 Email taslak olarak kaydedildi")
            case .cancelled:
                print("❌ Email gönderimi iptal edildi")
            case .failed:
                print("💥 Email gönderimi başarısız")
            @unknown default:
                print("❓ Bilinmeyen email durumu")
            }
        }
    }
}

// MARK: - Meeting Extension for Email
extension Meeting {
    var emailFriendlyDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}
