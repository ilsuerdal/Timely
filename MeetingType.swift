//
//  MeetingType.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation

struct MeetingType: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: Int
    var platform: MeetingPlatform
    var description: String
}
