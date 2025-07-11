//
//  Contact.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import Foundation

struct Contact: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var meetingCount: Int = 0
}
