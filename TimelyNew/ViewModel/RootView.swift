// RootView.swift - Ana kontrol dosyası (Tab Bar Kaldırıldı)

import SwiftUI
import Firebase
import FirebaseAuth

struct RootView: View {
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var viewModel = TimelyViewModel()
    @State private var isLoading = true
    @State private var userProfile: UserProfile?
    
    var body: some View {
        Group {
            if isLoading {
               LoadingView()
            } else if authManager.isLoggedIn {
                // Kullanıcı giriş yapmış
                if let profile = userProfile, profile.isOnboardingCompleted {
                    // Onboarding tamamlanmış → HomeView (TAB BAR YOK)
                    HomeView()
                        .environmentObject(authManager)
                        .environmentObject(viewModel)
                } else {
                    // Onboarding tamamlanmamış → Sorular
                    QuestionFlowView(
                        firstName: userProfile?.firstName ?? extractFirstName(from: authManager.currentUser?.displayName ?? authManager.currentUser?.email ?? "User"),
                        email: userProfile?.email ?? authManager.currentUser?.email ?? ""
                    )
                }
            } else {
                // Kullanıcı giriş yapmamış → Login
                MainLoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: authManager.isLoggedIn) {
            if authManager.isLoggedIn {
                loadUserProfile()
            } else {
                userProfile = nil
                isLoading = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
            // Onboarding tamamlandığında profili yeniden yükle
            loadUserProfile()
        }
    }
    
    private func checkAuthenticationState() {
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                if authManager.isLoggedIn {
                    loadUserProfile()
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            isLoading = false
            return
        }
        
        UserDataManager.shared.getUserProfile(userId: currentUser.uid) { profile, error in
            Task { @MainActor in
                if let profile = profile {
                    // Profil var - Mevcut kullanıcı
                    self.userProfile = profile
                    print("✅ Mevcut kullanıcı profili yüklendi: \(profile.firstName)")
                    print("📋 Onboarding durumu: \(profile.isOnboardingCompleted ? "Tamamlanmış" : "Tamamlanmamış")")
                } else {
                    // Profil yok - Yeni kullanıcı (Sign up'tan geldi)
                    print("❌ Kullanıcı profili bulunamadı, yeni kullanıcı - onboarding'e yönlendirilecek")
                    self.userProfile = UserProfile(
                        id: currentUser.uid,
                        firstName: self.extractFirstName(from: currentUser.displayName ?? currentUser.email ?? "User"),
                        lastName: self.extractLastName(from: currentUser.displayName ?? ""),
                        email: currentUser.email ?? ""
                    )
                    // isOnboardingCompleted default olarak false
                }
                self.isLoading = false
            }
        }
    }
    
    private func extractFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "User"
    }
    
    private func extractLastName(from fullName: String) -> String {
        let components = fullName.components(separatedBy: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
    }
}



// MARK: - QuestionFlowView (Onboarding Sorular)
struct QuestionFlowView: View {
    let firstName: String
    let email: String
    
    @State private var currentPage = 0
    @State private var selectedOption = ""
    @State private var textInput = ""
    @State private var isSavingProfile = false
    
    // Yanıtları sakla
    @State private var answers: [String] = Array(repeating: "", count: 5)
    
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    // ✅ Navigation için callback
    @Environment(\.dismiss) private var dismiss
    
    let questions = [
        OnboardingQuestion(
            title: "Timely'yi ne için kullanmak istiyorsunuz?",
            type: .multipleChoice,
            options: [
                ("Kişisel", "person"),
                ("İş", "briefcase"),
                ("Her ikisi", "person.2")
            ]
        ),
        OnboardingQuestion(
            title: "Unvanınız nedir?",
            type: .textInput,
            placeholder: "Örn: iOS Developer, Proje Yöneticisi"
        ),
        OnboardingQuestion(
            title: "Hangi departmanda çalışıyorsunuz?",
            type: .textInput,
            placeholder: "Örn: Mobil Geliştirme, İnsan Kaynakları"
        ),
        OnboardingQuestion(
            title: "Kendinizi kısaca tanıtır mısınız?",
            type: .textInput,
            placeholder: "Örn: 5 yıllık deneyimli iOS geliştiricisi...",
            isLongText: true
        ),
        OnboardingQuestion(
            title: "Toplantıları nasıl planlamayı tercih edersiniz?",
            type: .multipleChoice,
            options: [
                ("Manuel", "hand.tap"),
                ("Otomatik", "sparkles"),
                ("Karma", "slider.horizontal.3")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.9),
                    Color(red: 0.6, green: 0.4, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Profilinizi oluşturmak için birkaç soru sormak istiyoruz")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 60)
                    
                    Text(questions[currentPage].title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 40)
                
                // Question Content
                VStack(spacing: 20) {
                    if questions[currentPage].type == .multipleChoice {
                        // Multiple Choice Options
                        VStack(spacing: 16) {
                            ForEach(questions[currentPage].options ?? [], id: \.0) { option in
                                OptionButton(
                                    text: option.0,
                                    icon: option.1,
                                    isSelected: selectedOption == option.0
                                ) {
                                    selectedOption = option.0
                                    textInput = ""
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    } else {
                        // Text Input
                        VStack(spacing: 16) {
                            if questions[currentPage].isLongText {
                                // Long text area
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack(alignment: .topLeading) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(height: 120)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        if textInput.isEmpty {
                                            Text(questions[currentPage].placeholder ?? "")
                                                .foregroundColor(.white.opacity(0.6))
                                                .padding(.horizontal, 16)
                                                .padding(.top, 12)
                                        }
                                        
                                        TextEditor(text: $textInput)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .font(.system(size: 16))
                                    }
                                }
                            } else {
                                // Single line input
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 56)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    if textInput.isEmpty {
                                        Text(questions[currentPage].placeholder ?? "")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.leading, 16)
                                    }
                                    
                                    TextField("", text: $textInput)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .onAppear {
                            selectedOption = ""
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 30)
                
                // Continue Button
                Button(action: {
                    if currentPage < questions.count - 1 {
                        goToNextPage()
                    } else {
                        finishOnboarding()
                    }
                }) {
                    HStack {
                        if isSavingProfile {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                .scaleEffect(0.9)
                        } else {
                            Text(currentPage < questions.count - 1 ? "Devam Et" : "Başla")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .disabled(isCurrentAnswerEmpty || isSavingProfile)
                .opacity(isCurrentAnswerEmpty || isSavingProfile ? 0.6 : 1.0)
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Load saved answers if any
            if !answers[currentPage].isEmpty {
                if questions[currentPage].type == .multipleChoice {
                    selectedOption = answers[currentPage]
                } else {
                    textInput = answers[currentPage]
                }
            }
        }
    }
    
    private var isCurrentAnswerEmpty: Bool {
        if questions[currentPage].type == .multipleChoice {
            return selectedOption.isEmpty
        } else {
            return textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func goToNextPage() {
        // Save current answer
        if questions[currentPage].type == .multipleChoice {
            answers[currentPage] = selectedOption
        } else {
            answers[currentPage] = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Move to next page
        currentPage += 1
        
        // Load next page answer if exists
        if currentPage < questions.count {
            if questions[currentPage].type == .multipleChoice {
                selectedOption = answers[currentPage]
                textInput = ""
            } else {
                textInput = answers[currentPage]
                selectedOption = ""
            }
        }
    }
    
    private func finishOnboarding() {
        // Save last answer
        if questions[currentPage].type == .multipleChoice {
            answers[currentPage] = selectedOption
        } else {
            answers[currentPage] = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let currentUser = authManager.currentUser else { return }
        
        isSavingProfile = true
        
        // Create UserProfile with all answers
        var profile = UserProfile(
            id: currentUser.uid,
            firstName: firstName,
            lastName: "",
            email: email
        )
        
        // Map answers to profile fields
        profile.purpose = answers[0] // Timely kullanım amacı
        profile.jobTitle = answers[1] // Unvan
        profile.department = answers[2] // Departman
        profile.bio = answers[3] // Kendini tanıtma
        profile.schedulingPreference = answers[4] // Planlama tercihi
        profile.isOnboardingCompleted = true // ÖNEMLİ!
        
        UserDataManager.shared.saveUserProfile(profile) { success, error in
            DispatchQueue.main.async {
                isSavingProfile = false
                
                if success {
                    print("✅ Onboarding tamamlandı ve profil kaydedildi")
                    // AuthManager'a haber ver ki RootView yeniden render olsun
                    NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
                } else {
                    print("❌ Profil kaydetme hatası: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
}

// MARK: - OptionButton Component
struct OptionButton: View {
    let text: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(text)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(isSelected ? 0.5 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - MainLoginView (Güncellenmiş - Sorular Olmadan)
struct MainLoginView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSignUp = false
    @State private var rememberMe = false
    
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
            .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo ve başlık
                    VStack(spacing: 25) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Timely")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Toplantılarınızı kolayca yönetin")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Giriş Formu
                    VStack(spacing: 24) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("example@email.com", text: $email)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Şifre")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            SecureField("••••••••", text: $password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                        }
                        
                        // Remember Me & Forgot Password
                        HStack {
                            Button(action: { rememberMe.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.white)
                                    Text("Beni hatırla")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: resetPassword) {
                                Text("Şifremi Unuttum?")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.horizontal, 30)
                    
                    // Login Button
                    Button(action: loginWithEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Giriş Yap")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 30)
                    
                    // Sign Up Link
                    HStack {
                        Text("Hesabınız yok mu?")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Kayıt Ol") {
                            showingSignUp = true
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .underline()
                    }
                    .font(.system(size: 16))
                    
                    Spacer()
                }
                .padding(.vertical, 50)
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .alert("Bilgi", isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
    }
    
    private func loginWithEmail() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                isLoading = false
                
                if let error = error {
                    alertMessage = getFirebaseErrorMessage(error)
                    showingAlert = true
                    print("❌ Giriş hatası: \(error.localizedDescription)")
                } else {
                    print("✅ GİRİŞ BAŞARILI - Mevcut kullanıcı HomeView'e yönlendirilecek")
                    // Firebase auth manager otomatik olarak durumu güncelleyecek
                    // RootView bu değişikliği algılayıp HomeView'e götürecek
                }
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen önce email adresinizi girin."
            showingAlert = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            Task { @MainActor in
                if let error = error {
                    alertMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
                } else {
                    alertMessage = "Şifre sıfırlama bağlantısı \(email) adresine gönderildi."
                }
                showingAlert = true
            }
        }
    }
    
    private func getFirebaseErrorMessage(_ error: Error) -> String {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return error.localizedDescription
        }
        
        switch errorCode {
        case .userNotFound:
            return "Bu email adresi ile kayıtlı kullanıcı bulunamadı."
        case .wrongPassword:
            return "Hatalı şifre girdiniz."
        case .invalidEmail:
            return "Geçersiz email adresi."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin."
        case .tooManyRequests:
            return "Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin."
        case .userDisabled:
            return "Bu hesap devre dışı bırakılmış."
        default:
            return error.localizedDescription
        }
    }
}
