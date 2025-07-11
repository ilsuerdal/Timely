//
//  LoadingView.swift
//  TimelyNew
//
//  Created by ilsu on 19.06.2025.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.9),
                    Color(red: 0.6, green: 0.4, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
          
            
            VStack(spacing: 30) {
                // Animated Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(scale)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: scale
                        )
                    
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false),
                            value: rotationAngle
                        )
                }
                .onAppear {
                    rotationAngle = 360
                    scale = 1.1
                }
                
                VStack(spacing: 12) {
                    Text("Timely")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Yükleniyor...")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Animated dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 8, height: 8)
                                .scaleEffect(scale)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: scale
                                )
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

#Preview {
    LoadingView()
}
