//
//  Availability.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import Foundation

struct Availability: Codable {
    var workDays: Set<WeekDay>
    var startTime: Date
    var endTime: Date
    var timezone: String
}
