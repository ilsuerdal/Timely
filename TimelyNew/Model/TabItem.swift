//
//  TabItem.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import Foundation

enum TabItem: String, CaseIterable {
    case home = "Ana Sayfa"
    case calendar = "Takvim"
    case add = "Ekle"
    case contacts = "Kişiler"
    case notifications = "Bildirimler"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .add: return "plus.circle.fill"
        case .contacts: return "person.2.fill"
        case .notifications: return "bell.fill"
        }
    }
}
