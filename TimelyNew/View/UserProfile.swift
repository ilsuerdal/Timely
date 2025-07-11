//
//  UserProfile.swift
//  TimelyNew
//
//  Created by ilsu on 26.06.2025.
//

import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable, Identifiable {
    let id: String
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
    
    // Yeni eklenen alanlar (5 sorulu onboarding için)
    var jobTitle: String // Unvan
    var department: String // Departman
    var bio: String // Kendini tanıtma
    
    // MARK: - Initializers
    
    // Basit initializer (yeni kullanıcılar için)
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
        self.jobTitle = ""
        self.department = ""
        self.bio = ""
    }
    
    // MARK: - Computed Properties
    
    var fullName: String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        return fullName
    }
}
