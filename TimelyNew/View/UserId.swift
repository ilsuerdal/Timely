// DynamicProfileView.swift - Sadece UserProfile kullanan temiz versiyon

import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - Dinamik Profil View (Firebase ile entegre)
struct DynamicProfileView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var showingEditProfile = false
    @State private var errorMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let profile = userProfile {
                    profileContentView(profile)
                } else {
                    errorView
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Düzenle") {
                        showingEditProfile = true
                    }
                    .disabled(userProfile == nil)
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .refreshable {
                await refreshUserProfile()
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile = userProfile {
                    EditProfileView(userProfile: profile) { updatedProfile in
                        self.userProfile = updatedProfile
                    }
                }
            }
            .alert("Hata", isPresented: $showingAlert) {
                Button("Tamam") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Profil yükleniyor...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Profil Yüklenemedi")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Profil bilgileriniz yüklenirken bir hata oluştu.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Tekrar Dene") {
                loadUserProfile()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Profile Content View
    private func profileContentView(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeaderSection(profile)
                
                // Quick Actions
                quickActionsSection
                
                // Profile Information
                profileInfoSection(profile)
                
                // Onboarding Responses
                onboardingResponsesSection(profile)
                
                // Account Actions
                accountActionsSection
                
                Spacer().frame(height: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Profile Header Section
    private func profileHeaderSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .overlay(
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Profile Image
                    AsyncImage(url: URL(string: profile.avatarURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .overlay(
                                Text(String(profile.firstName.prefix(1)))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(radius: 10)
                    
                    // Name and Email
                    VStack(spacing: 4) {
                        Text(profile.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer().frame(height: 20)
                }
            )
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingEditProfile = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                    Text("Profili Düzenle")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            
            Button(action: shareProfile) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Profili Paylaş")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Profile Info Section
    private func profileInfoSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Kişisel Bilgiler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ProfileInfoRow(
                    icon: "person.fill",
                    title: "Ad Soyad",
                    value: profile.displayName,
                    color: .blue
                )
                
                ProfileInfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: profile.email,
                    color: .green
                )
                
                if !profile.phoneNumber.isEmpty {
                    ProfileInfoRow(
                        icon: "phone.fill",
                        title: "Telefon",
                        value: profile.phoneNumber,
                        color: .orange
                    )
                }
                
                ProfileInfoRow(
                    icon: "calendar",
                    title: "Üyelik Tarihi",
                    value: formatDate(profile.createdAt),
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Onboarding Responses Section
    private func onboardingResponsesSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tercihlerim")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if !profile.purpose.isEmpty {
                    ProfileInfoRow(
                        icon: "target",
                        title: "Kullanım Amacı",
                        value: profile.purpose,
                        color: .indigo
                    )
                }
                
                if !profile.schedulingPreference.isEmpty {
                    ProfileInfoRow(
                        icon: "calendar.badge.plus",
                        title: "Planlama Tercihi",
                        value: profile.schedulingPreference,
                        color: .cyan
                    )
                }
                
                if !profile.calendarProvider.isEmpty {
                    ProfileInfoRow(
                        icon: "calendar.circle",
                        title: "Takvim Sağlayıcısı",
                        value: profile.calendarProvider,
                        color: .mint
                    )
                }
                
                ProfileInfoRow(
                    icon: profile.isOnboardingCompleted ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                    title: "Onboarding Durumu",
                    value: profile.isOnboardingCompleted ? "Tamamlandı" : "Tamamlanmadı",
                    color: profile.isOnboardingCompleted ? .green : .orange
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Account Actions Section
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Hesap İşlemleri")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "arrow.clockwise",
                    title: "Profili Yenile",
                    subtitle: "En güncel bilgileri getir",
                    color: .blue,
                    action: loadUserProfile
                )
                
                ActionButton(
                    icon: "person.badge.minus",
                    title: "Onboarding'i Sıfırla",
                    subtitle: "İlk kurulum sorularını tekrar cevapla",
                    color: .orange,
                    action: resetOnboarding
                )
                
                ActionButton(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Çıkış Yap",
                    subtitle: "Hesabınızdan güvenli şekilde çıkış yapın",
                    color: .red,
                    action: signOut
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Functions
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı."
            showingAlert = true
            isLoading = false
            return
        }
        
        print("🔄 Profil yükleniyor - User ID: \(currentUser.uid)")
        isLoading = true
        
        UserDataManager.shared.getUserProfile(userId: currentUser.uid) { profile, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let profile = profile {
                    self.userProfile = profile
                    print("✅ Profil başarıyla yüklendi: \(profile.firstName)")
                } else if let error = error {
                    errorMessage = "Profil yüklenirken hata: \(error.localizedDescription)"
                    showingAlert = true
                    print("❌ Profil yükleme hatası: \(error.localizedDescription)")
                } else {
                    errorMessage = "Profil bulunamadı. Onboarding'i yeniden tamamlamanız gerekebilir."
                    showingAlert = true
                    print("❌ Profil bulunamadı")
                }
            }
        }
    }
    
    @MainActor
    private func refreshUserProfile() async {
        guard let currentUser = authManager.currentUser else { return }
        
        await withCheckedContinuation { continuation in
            UserDataManager.shared.getUserProfile(userId: currentUser.uid) { profile, error in
                DispatchQueue.main.async {
                    if let profile = profile {
                        self.userProfile = profile
                        print("🔄 Profil yenilendi: \(profile.firstName)")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func shareProfile() {
        guard let profile = userProfile else { return }
        
        let shareText = """
        📱 Timely Profili
        
        👤 \(profile.displayName)
        📧 \(profile.email)
        
        Benimle toplantı planlamak için Timely uygulamasını kullanabilirsiniz!
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func resetOnboarding() {
        guard let currentUser = authManager.currentUser else { return }
        
        // Onboarding'i sıfırla
        var updatedProfile = userProfile
        updatedProfile?.isOnboardingCompleted = false
        
        if let profile = updatedProfile {
            UserDataManager.shared.saveUserProfile(profile) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Onboarding sıfırlandı")
                        // RootView'in state'ini güncelle
                        NotificationCenter.default.post(name: Notification.Name("onboardingReset"), object: nil)
                    } else {
                        errorMessage = "Onboarding sıfırlanırken hata oluştu."
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            print("✅ Kullanıcı başarıyla çıkış yaptı")
        } catch let signOutError as NSError {
            errorMessage = "Çıkış yapılırken hata: \(signOutError.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editableProfile: UserProfile
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onSave: (UserProfile) -> Void
    
    init(userProfile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self._editableProfile = State(initialValue: userProfile)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Ad", text: $editableProfile.firstName)
                    TextField("Soyad", text: $editableProfile.lastName)
                    TextField("Telefon", text: $editableProfile.phoneNumber)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Kişisel Bilgiler")
                }
                
                Section {
                    Picker("Kullanım Amacı", selection: $editableProfile.purpose) {
                        Text("Seçiniz").tag("")
                        Text("Kişisel").tag("Kişisel")
                        Text("İş").tag("İş")
                        Text("Her ikisi").tag("Her ikisi")
                    }
                    
                    Picker("Planlama Tercihi", selection: $editableProfile.schedulingPreference) {
                        Text("Seçiniz").tag("")
                        Text("Manuel").tag("Manuel")
                        Text("Otomatik").tag("Otomatik")
                        Text("Karma").tag("Karma")
                    }
                    
                    Picker("Takvim Sağlayıcısı", selection: $editableProfile.calendarProvider) {
                        Text("Seçiniz").tag("")
                        Text("Google Calendar").tag("Google Calendar")
                        Text("Outlook Calendar").tag("Outlook Calendar")
                        Text("Exchange Calendar").tag("Exchange Calendar")
                    }
                } header: {
                    Text("Tercihler")
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Bilgi", isPresented: $showingAlert) {
                Button("Tamam") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        UserDataManager.shared.saveUserProfile(editableProfile) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    alertMessage = "Profil başarıyla güncellendi."
                    showingAlert = true
                    onSave(editableProfile)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                } else {
                    alertMessage = "Profil güncellenirken hata oluştu: \(error?.localizedDescription ?? "")"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DynamicProfileView()
        .environmentObject(FirebaseAuthManager.shared)
}
