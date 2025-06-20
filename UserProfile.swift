//
//  UserProfile.swift
//  TimelyNew
//
//  Created by ilsu on 20.06.2025.
//


import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    
    // Onboarding Soru Cevapları
    var purpose: String // Kişisel, İş, Her ikisi
    var schedulingPreference: String // Manuel, Otomatik, Karma
    var calendarProvider: String // Google Calendar, Exchange Calendar, Outlook Calendar
    
    var isOnboardingCompleted: Bool
    var createdAt: Date
    
    // Ek alanlar
    var phoneNumber: String
    var avatarURL: String
    
    
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
        self.phoneNumber = ""
        self.avatarURL = ""
    }
    
    // Computed properties for easy access
    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var displayName: String {
        return fullName.isEmpty ? firstName : fullName
    }
}
