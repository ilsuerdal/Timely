//
//  UserProfile.swift
//  TimelyNew
//
//  Created by ilsu on 10.06.2025.
//

import Foundation
import Foundation
// MARK: - User Profile Model (Ayrı bir dosyaya koyun: UserProfile.swift)
struct UserProfile: Codable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var purpose: String // Personal, Work, Both
    var schedulingPreference: String // Manually, Automatically, Mixed
    var calendarProvider: String // Google Calendar, Exchange Calendar, Outlook Calendar
    var isOnboardingCompleted: Bool
    var createdAt: Date
    
    init(id: String, firstName: String, lastName: String = "", email: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.purpose = ""
        self.schedulingPreference = ""
        self.calendarProvider = ""
        self.isOnboardingCompleted = false
        self.createdAt = Date()
        
    }
}
