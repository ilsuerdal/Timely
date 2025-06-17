//
//  Meeting.swift
//  Timely
//
//  Created by ilsu on 19.05.2025.
//

import Foundation
struct Meeting: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
