import SwiftUI
import Foundation

struct AvailabilityView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedWorkDays: Set<WeekDay> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var startTime = createValidDate(hour: 9, minute: 0)
    @State private var endTime = createValidDate(hour: 17, minute: 0)
    @State private var selectedTimezone = TimeZone.current.identifier
    @State private var isSaving = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var saveAlertTitle = ""
    
    private let timezones = [
        "Europe/Istanbul",
        "America/New_York",
        "America/Los_Angeles",
        "Europe/London",
        "Asia/Tokyo",
        "Australia/Sydney"
    ]
    
    // Safe date creation function
    private static func createValidDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0
        
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    VStack(spacing: 20) {
                        workDaysSection
                        timeRangeSection
                        timezoneSection
                    }
                    .padding(.horizontal)
                    
                    saveButton
                }
                .padding(.vertical)
            }
            .navigationTitle("Müsaitlik Ayarları")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("İptal") {
                    DispatchQueue.main.async {
                        dismiss()
                    }
                },
                trailing: Button("Kaydet") {
                    saveAvailability()
                }
                .disabled(isSaving)
            )
        }
        .onAppear {
            loadCurrentAvailability()
        }
        .alert(saveAlertTitle, isPresented: $showingSaveAlert) {
            Button("Tamam") {
                if saveAlertTitle == "Başarılı!" {
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Çalışma Saatlerinizi Belirleyin")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Bu ayarlar toplantı davetiyelerinde kullanılacak")
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
    }
    
    private var workDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Çalışma Günleri", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(WeekDay.allCases, id: \.self) { day in
                    WorkDayCard(
                        day: day,
                        isSelected: selectedWorkDays.contains(day)
                    ) {
                        toggleWorkDay(day)
                    }
                }
            }
        }
    }
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Çalışma Saatleri", systemImage: "clock")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Başlangıç")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .onChange(of: startTime) { newValue in
                            // Ensure valid date
                            startTime = normalizeTime(newValue)
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bitiş")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .onChange(of: endTime) { newValue in
                            // Ensure valid date
                            endTime = normalizeTime(newValue)
                        }
                }
            }
            
            // Çalışma saati özeti
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Günlük \(workingHours) saat çalışma süresi")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Saat Dilimi", systemImage: "globe")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Saat Dilimi", selection: $selectedTimezone) {
                ForEach(timezones, id: \.self) { timezone in
                    Text(timezoneDisplayName(timezone))
                        .tag(timezone)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveAvailability) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "Kaydediliyor..." : "Ayarları Kaydet")
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
            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .disabled(isSaving || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Computed Properties
    
    private var workingHours: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime, to: endTime)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if minutes == 0 {
            return "\(hours)"
        } else {
            return "\(hours).\(minutes < 30 ? "5" : "0")"
        }
    }
    
    private var isFormValid: Bool {
        return !selectedWorkDays.isEmpty && startTime < endTime
    }
    
    // MARK: - Helper Methods
    
    private func normalizeTime(_ date: Date) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0
        components.nanosecond = 0
        
        return calendar.date(from: components) ?? date
    }
    
    private func toggleWorkDay(_ day: WeekDay) {
        DispatchQueue.main.async {
            if self.selectedWorkDays.contains(day) {
                self.selectedWorkDays.remove(day)
            } else {
                self.selectedWorkDays.insert(day)
            }
        }
    }
    
    private func timezoneDisplayName(_ identifier: String) -> String {
        let timezone = TimeZone(identifier: identifier)
        return timezone?.localizedName(for: .standard, locale: Locale.current) ?? identifier
    }
    
    private func loadCurrentAvailability() {
        DispatchQueue.main.async {
            // ViewModel'den mevcut ayarları yükle
            self.selectedWorkDays = self.viewModel.availability.workDays
            
            // Safe time loading
            self.startTime = self.normalizeTime(self.viewModel.availability.startTime)
            self.endTime = self.normalizeTime(self.viewModel.availability.endTime)
            self.selectedTimezone = self.viewModel.availability.timezone
        }
        
        // Firebase'den de yükle (background'da)
        FirebaseDataManager.shared.loadAvailability { availability, error in
            DispatchQueue.main.async {
                if let availability = availability {
                    self.selectedWorkDays = availability.workDays
                    self.startTime = self.normalizeTime(availability.startTime)
                    self.endTime = self.normalizeTime(availability.endTime)
                    self.selectedTimezone = availability.timezone
                    print("✅ Müsaitlik ayarları Firebase'den yüklendi")
                } else if let error = error {
                    print("❌ Müsaitlik yükleme hatası: \(error)")
                }
            }
        }
    }
    
    private func saveAvailability() {
        // UI thread'de form validasyonunu yap
        guard isFormValid else {
            DispatchQueue.main.async {
                self.saveAlertTitle = "Hata"
                self.saveAlertMessage = "Lütfen en az bir çalışma günü seçin ve geçerli saat aralığı girin."
                self.showingSaveAlert = true
            }
            return
        }
        
        // UI state'i güncelle
        DispatchQueue.main.async {
            self.isSaving = true
        }
        
        // Safe date normalization before saving
        let normalizedStartTime = normalizeTime(startTime)
        let normalizedEndTime = normalizeTime(endTime)
        
        // Debug: Print dates before creating availability
        print("🔍 Saving dates debug:")
        print("   - Start Time: \(normalizedStartTime)")
        print("   - End Time: \(normalizedEndTime)")
        print("   - Start Timestamp: \(normalizedStartTime.timeIntervalSince1970)")
        print("   - End Timestamp: \(normalizedEndTime.timeIntervalSince1970)")
        
        // Check for invalid timestamps
        if normalizedStartTime.timeIntervalSince1970 < 0 || normalizedEndTime.timeIntervalSince1970 < 0 {
            DispatchQueue.main.async {
                self.isSaving = false
                self.saveAlertTitle = "Hata"
                self.saveAlertMessage = "Geçersiz saat değeri. Lütfen saatleri tekrar seçin."
                self.showingSaveAlert = true
            }
            return
        }
        
        // Availability objesi oluştur
        let newAvailability = Availability(
            workDays: selectedWorkDays,
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            timezone: selectedTimezone
        )
        
        // Önce ViewModel'i güncelle (main thread'de)
        DispatchQueue.main.async {
            self.viewModel.updateAvailability(newAvailability)
        }
        
        // Sonra Firebase'e kaydet (background'da)
        FirebaseDataManager.shared.saveAvailability(newAvailability) { success, error in
            // UI güncellemesi main thread'de yapılacak
            DispatchQueue.main.async {
                self.isSaving = false
                
                if success {
                    self.saveAlertTitle = "Başarılı!"
                    self.saveAlertMessage = "Müsaitlik ayarlarınız başarıyla kaydedildi."
                    print("✅ Müsaitlik ayarları Firebase'e kaydedildi")
                } else {
                    self.saveAlertTitle = "Hata"
                    self.saveAlertMessage = "Ayarlar kaydedilirken bir hata oluştu: \(error?.localizedDescription ?? "Bilinmeyen hata")"
                    print("❌ Müsaitlik kaydetme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                }
                
                self.showingSaveAlert = true
            }
        }
    }
}

// MARK: - Work Day Card Component
struct WorkDayCard: View {
    let day: WeekDay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayAbbreviation)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(day.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dayAbbreviation: String {
        switch day {
        case .monday: return "Pzt"
        case .tuesday: return "Sal"
        case .wednesday: return "Çar"
        case .thursday: return "Per"
        case .friday: return "Cum"
        case .saturday: return "Cmt"
        case .sunday: return "Paz"
        }
    }
}

#Preview {
    AvailabilityView()
        .environmentObject(TimelyViewModel())
}
