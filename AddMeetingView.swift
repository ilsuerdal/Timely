//
//  AddMeetingView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//


import SwiftUI

struct AddMeetingView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @State private var meetingTitle = ""
    @State private var selectedDate = Date()
    @State private var selectedDuration = 30
    @State private var participantEmail = ""
    @State private var selectedPlatform = MeetingPlatform.googleMeet
    @State private var selectedMeetingType = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    let durations = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    VStack(spacing: 20) {
                        meetingTitleSection
                        dateTimeSection
                        durationSection
                        meetingTypeSection
                        platformSection
                        participantSection
                    }
                    .padding(.horizontal)
                    
                    saveButton
                }
                .padding(.vertical)
            }
            .navigationTitle("Yeni Toplantı")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Başarılı!", isPresented: $showingSuccessAlert) {
            Button("Tamam") {
                clearForm()
                viewModel.selectedTab = .calendar
            }
        } message: {
            Text("Toplantı başarıyla eklendi!")
        }
        .alert("Hata!", isPresented: $showingErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Yeni Toplantı Oluştur")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Toplantı detaylarını doldurun")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    }
    
    private var meetingTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Toplantı Başlığı", systemImage: "text.cursor")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Örn: Proje Değerlendirmesi", text: $meetingTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tarih ve Saat", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
            DatePicker("", selection: $selectedDate, in: Date()...)
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Süre", systemImage: "clock")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Süre", selection: $selectedDuration) {
                ForEach(durations, id: \.self) { duration in
                    Text("\(duration) dakika").tag(duration)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var meetingTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Toplantı Türü", systemImage: "tag")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.meetingTypes.isEmpty {
                Text("Henüz toplantı türü yok")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Picker("Toplantı Türü", selection: $selectedMeetingType) {
                    Text("Seçiniz").tag("")
                    ForEach(viewModel.meetingTypes) { type in
                        Text(type.name).tag(type.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Platform", systemImage: "video")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MeetingPlatform.allCases, id: \.self) { platform in
                    PlatformCard(
                        platform: platform,
                        isSelected: selectedPlatform == platform
                    ) {
                        selectedPlatform = platform
                    }
                }
            }
        }
    }
    
    private var participantSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Katılımcı Email", systemImage: "person")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("ornek@email.com", text: $participantEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveMeeting) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Toplantıyı Kaydet")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var isFormValid: Bool {
        !meetingTitle.isEmpty &&
        !participantEmail.isEmpty &&
        isValidEmail(participantEmail)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    private func saveMeeting() {
        // Form validation
        guard isFormValid else {
            errorMessage = "Lütfen tüm alanları doğru şekilde doldurun."
            showingErrorAlert = true
            return
        }
        
        // Meeting type kontrolü
        let finalMeetingType = selectedMeetingType.isEmpty ? "Genel Toplantı" : selectedMeetingType
        
        // Meeting objesi oluştur
        let newMeeting = Meeting(
            title: meetingTitle,
            date: selectedDate,
            duration: selectedDuration,
            platform: selectedPlatform,
            participantEmail: participantEmail.lowercased(),
            meetingType: finalMeetingType
        )
        
        // ViewModel'e ekle
        viewModel.addMeeting(newMeeting)
        
        // Başarı mesajı göster
        showingSuccessAlert = true
    }
    
    private func clearForm() {
        meetingTitle = ""
        selectedDate = Date()
        selectedDuration = 30
        participantEmail = ""
        selectedPlatform = .googleMeet
        selectedMeetingType = ""
    }
}

struct PlatformCard: View {
    let platform: MeetingPlatform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddMeetingView()
        .environmentObject(TimelyViewModel())
}
