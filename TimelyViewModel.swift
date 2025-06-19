//
//  TimelyViewModel.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import SwiftUI
import Foundation

class TimelyViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var meetingTypes: [MeetingType] = []
    @Published var contacts: [Contact] = []
    @Published var availability: Availability
    @Published var selectedTab: TabItem = .home
    
    init() {
        // Default availability
        let calendar = Calendar.current
        let startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        let endTime = calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
        
        self.availability = Availability(
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            startTime: startTime,
            endTime: endTime,
            timezone: "Europe/Istanbul"
        )
        
        setupSampleData()
    }
    
    private func setupSampleData() {
        meetingTypes = [
            MeetingType(name: "30 Dakika - Genel Görüşme", duration: 30, platform: .googleMeet, description: "Kısa ve verimli görüşmeler için"),
            MeetingType(name: "60 Dakika - Detaylı Görüşme", duration: 60, platform: .googleMeet, description: "Uzun ve detaylı tartışmalar için"),
            MeetingType(name: "Danışmanlık", duration: 45, platform: .zoom, description: "Profesyonel danışmanlık hizmetleri")
        ]
        
        contacts = [
            Contact(name: "Ahmet Yılmaz", email: "ahmet@example.com", meetingCount: 5),
            Contact(name: "Zeynep Kaya", email: "zeynep@example.com", meetingCount: 3),
            Contact(name: "Mehmet Demir", email: "mehmet@example.com", meetingCount: 2)
        ]
    }
    
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
        // Update contact meeting count
        if let contactIndex = contacts.firstIndex(where: { $0.email == meeting.participantEmail }) {
            contacts[contactIndex].meetingCount += 1
        } else {
            // Create new contact
            let name = meeting.participantEmail.components(separatedBy: "@").first?.capitalized ?? "Unknown"
            let newContact = Contact(name: name, email: meeting.participantEmail, meetingCount: 1)
            contacts.append(newContact)
        }
    }
    
    func addMeetingType(_ meetingType: MeetingType) {
        meetingTypes.append(meetingType)
    }
    
    func updateAvailability(_ newAvailability: Availability) {
        availability = newAvailability
    }
    
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
}
