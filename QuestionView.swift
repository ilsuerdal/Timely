//
//  QuestionView.swift
//  Timely
//
//  Created by ilsu on 20.05.2025.
//

import Foundation
import SwiftUI

struct QuestionView: View {
    let question: String
    let optionsWithIcons: [(String, String)]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(question)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(optionsWithIcons, id: \.0) { option, iconName in
                    Button(action: {
                        selectedOption = option
                    }) {
                        HStack {
                            Image(systemName: iconName)
                                .frame(width: 24, height: 24)
                                .foregroundColor(selectedOption == option ? .white : .blue)
                            
                            Text(option)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedOption == option ? Color.blue : Color.blue.opacity(0.1))
                        )
                        .foregroundColor(selectedOption == option ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}
