//
//  MeetingPlatform.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import Foundation

enum MeetingPlatform: String, CaseIterable, Codable {
    case googleMeet = "Google Meet"
    case zoom = "Zoom"
    case teams = "Microsoft Teams"
    case inPerson = "Yüz Yüze"
    
    var icon: String {
        switch self {
        case .googleMeet: return "video.circle.fill"
        case .zoom: return "video.fill"
        case .teams: return "rectangle.3.group.fill"
        case .inPerson: return "person.2.fill"
        }
    }
}
