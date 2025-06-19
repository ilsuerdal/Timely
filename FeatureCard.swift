//
//  FeatureCard.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.title)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
