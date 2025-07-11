//
//  Notifications.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//
import Foundation
import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Bildirimler")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Ayarlar") {
                        // Bildirim ayarları
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Upcoming meetings notification
                        NotificationCard(
                            icon: "calendar.badge.clock",
                            iconColor: .blue,
                            title: "Yaklaşan Toplantılar",
                            subtitle: "Bugün 2 toplantınız var",
                            time: "10 dk önce"
                        )
                        
                        // Meeting reminder
                        NotificationCard(
                            icon: "bell.badge",
                            iconColor: .orange,
                            title: "Toplantı Hatırlatması",
                            subtitle: "Proje Değerlendirmesi toplantınız 30 dakika sonra başlayacak",
                            time: "30 dk önce"
                        )
                        
                        // New meeting request
                        NotificationCard(
                            icon: "person.badge.plus",
                            iconColor: .green,
                            title: "Yeni Toplantı Talebi",
                            subtitle: "Ahmet Yılmaz sizinle bir toplantı planlamak istiyor",
                            time: "2 saat önce"
                        )
                        
                        // Empty state for no notifications
                        if true { // Bu kısmı gerçek bildirim mantığıyla değiştirin
                            VStack(spacing: 20) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("Tüm bildirimler okundu")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Yeni bildirimleriniz burada görünecek")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
        }
    }
}

struct NotificationCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
