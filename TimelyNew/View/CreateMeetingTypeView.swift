//
//  CreateMeetingTypeView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct CreateMeetingTypeView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var duration = 30
    @State private var selectedPlatform = MeetingPlatform.googleMeet
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let durations = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Yeni Toplantı Türü")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Özel toplantı türünüzü oluşturun ve kaydedin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    VStack(spacing: 24) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "textformat")
                                    .foregroundColor(.blue)
                                Text("Toplantı Türü Adı")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("30 Dakika Görüşme", text: $name)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .font(.body)
                        }
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text("Açıklama")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            TextField("Kısa ve verimli görüşmeler için...", text: $description)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .font(.body)
                        }
                        
                        // Duration Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text("Toplantı Süresi")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Picker("Süre", selection: $duration) {
                                ForEach(durations, id: \.self) { dur in
                                    Text("\(dur) dakika").tag(dur)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Platform Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "video")
                                    .foregroundColor(.blue)
                                Text("Toplantı Platformu")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(MeetingPlatform.allCases, id: \.self) { platform in
                                    Button(action: {
                                        selectedPlatform = platform
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: platform.icon)
                                                .font(.title2)
                                                .foregroundColor(selectedPlatform == platform ? .white : .blue)
                                            
                                            Text(platform.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedPlatform == platform ? .white : .primary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedPlatform == platform ? Color.blue : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedPlatform == platform ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Preview Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "eye")
                                    .foregroundColor(.purple)
                                Text("Önizleme")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Toplantı Türü: \(name.isEmpty ? "Henüz girilmedi" : name)")
                                    .font(.subheadline)
                                
                                Text("Açıklama: \(description.isEmpty ? "Henüz girilmedi" : description)")
                                    .font(.subheadline)
                                
                                Text("Süre: \(duration) dakika")
                                    .font(.subheadline)
                                
                                Text("Platform: \(selectedPlatform.rawValue)")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: saveMeetingType) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Toplantı Türünü Oluştur")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .navigationTitle("Yeni Tür")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    dismiss()
                }
                .foregroundColor(.blue),
                trailing: Button("Kaydet") {
                    saveMeetingType()
                }
                .disabled(!isFormValid)
                .foregroundColor(isFormValid ? .blue : .gray)
            )
        }
        .alert("Bilgi", isPresented: $showingAlert) {
            Button("Tamam") {
                if alertMessage.contains("başarıyla") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveMeetingType() {
        guard isFormValid else {
            alertMessage = "Lütfen toplantı türü adını girin."
            showingAlert = true
            return
        }
        
        let newMeetingType = MeetingType(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: duration,
            platform: selectedPlatform,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        viewModel.addMeetingType(newMeetingType)
        
        alertMessage = "Toplantı türü '\(newMeetingType.name)' başarıyla oluşturuldu!"
        showingAlert = true
        
        print("✅ Yeni toplantı türü oluşturuldu:")
        print("   Ad: \(newMeetingType.name)")
        print("   Süre: \(newMeetingType.duration) dakika")
        print("   Platform: \(newMeetingType.platform.rawValue)")
        print("   Açıklama: \(newMeetingType.description)")
    }
}
