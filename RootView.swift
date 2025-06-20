// RootView.swift - Ana kontrol dosyası

import SwiftUI
import Firebase
import FirebaseAuth

struct RootView: View {
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var viewModel = TimelyViewModel() 
    @State private var isLoading = true
    @State private var userProfile: TimelyUserProfile?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                   LoadingView()
                } else if authManager.isLoggedIn {
                    // Kullanıcı giriş yapmış
                    if let profile = userProfile, profile.isOnboardingCompleted {
                        // Onboarding tamamlanmış → HomeView
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
                    // Profil var, TimelyUserProfile'a çevir
                    self.userProfile = TimelyUserProfile(
                        id: profile.id,
                        firstName: profile.firstName,
                        lastName: profile.lastName,
                        email: profile.email,
                        purpose: profile.purpose,
                        schedulingPreference: profile.schedulingPreference,
                        calendarProvider: profile.calendarProvider,
                        isOnboardingCompleted: profile.isOnboardingCompleted,
                        createdAt: profile.createdAt,
                        phoneNumber: profile.phoneNumber ?? "",
                        avatarURL: profile.avatarURL ?? ""
                    )
                    print("✅ Mevcut kullanıcı profili yüklendi: \(profile.firstName)")
                } else {
                    // Profil yok, yeni kullanıcı
                    print("❌ Kullanıcı profili bulunamadı, yeni kullanıcı olarak işaretlendi")
                    self.userProfile = TimelyUserProfile(
                        id: currentUser.uid,
                        firstName: self.extractFirstName(from: currentUser.displayName ?? currentUser.email ?? "User"),
                        email: currentUser.email ?? "",
                        isOnboardingCompleted: false // YENİ KULLANICI
                    )
                }
                self.isLoading = false
            }
        }
    }
    
    private func extractFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "User"
    }
}

// MARK: - TimelyUserProfile Model (Güncellenmiş)
struct TimelyUserProfile {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var purpose: String
    var schedulingPreference: String
    var calendarProvider: String
    var isOnboardingCompleted: Bool
    var createdAt: Date
    var phoneNumber: String
    var avatarURL: String
    
    init(id: String, firstName: String, lastName: String = "", email: String,
         purpose: String = "", schedulingPreference: String = "",
         calendarProvider: String = "", isOnboardingCompleted: Bool = false,
         createdAt: Date = Date(), phoneNumber: String = "", avatarURL: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.purpose = purpose
        self.schedulingPreference = schedulingPreference
        self.calendarProvider = calendarProvider
        self.isOnboardingCompleted = isOnboardingCompleted
        self.createdAt = createdAt
        self.phoneNumber = phoneNumber
        self.avatarURL = avatarURL
    }
}

// MARK: - QuestionFlowView (Onboarding Sorular)
struct QuestionFlowView: View {
    let firstName: String
    let email: String
    
    @State private var currentPage = 0
    @State private var selectedOption = ""
    @State private var showingHomeView = false
    @State private var isSavingProfile = false
    
    // Yanıtları sakla
    @State private var purpose = ""
    @State private var schedulingPreference = ""
    @State private var calendarProvider = ""
    
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Hoşgeldin, \(firstName)!")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 50)
                
                Group {
                    switch currentPage {
                    case 0:
                        QuestionView(
                            question: "Timely'i ne için kullanmak istiyorsun?",
                            optionsWithIcons: [
                                ("Kişisel", "person"),
                                ("İş", "briefcase"),
                                ("Her ikisi", "person.2")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 1:
                        QuestionView(
                            question: "Toplantıları nasıl planlamayı tercih ediyorsun?",
                            optionsWithIcons: [
                                ("Manuel", "hand.tap"),
                                ("Otomatik", "sparkles"),
                                ("Karışık", "slider.horizontal.3")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 2:
                        QuestionView(
                            question: "Hangi takvimi kullanacaksın?",
                            optionsWithIcons: [
                                ("Google Takvim", "calendar"),
                                ("Exchange Takvim", "tray.and.arrow.down.fill"),
                                ("Outlook Takvim", "envelope.badge")
                            ],
                            selectedOption: $selectedOption
                        )
                    default:
                        Text("Tamamlandı")
                    }
                }
                
                Spacer()
                
                // Butonlar
                if currentPage < 2 {
                    Button("Devam Et") {
                        goToNextPage()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedOption.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedOption.isEmpty)
                } else {
                    Button(isSavingProfile ? "Kaydediliyor..." : "Başla") {
                        finishOnboarding()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedOption.isEmpty || isSavingProfile ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedOption.isEmpty || isSavingProfile)
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showingHomeView) {
                HomeView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func goToNextPage() {
        // Mevcut sayfanın yanıtını kaydet
        saveCurrentPageResponse()
        
        // Sonraki sayfaya geç
        currentPage += 1
        selectedOption = ""
    }
    
    private func saveCurrentPageResponse() {
        if !selectedOption.isEmpty {
            switch currentPage {
            case 0:
                purpose = selectedOption
            case 1:
                schedulingPreference = selectedOption
            case 2:
                calendarProvider = selectedOption
            default:
                break
            }
        }
    }
    
    private func finishOnboarding() {
        // Son sayfanın yanıtını kaydet
        saveCurrentPageResponse()
        
        guard let currentUser = authManager.currentUser else { return }
        
        isSavingProfile = true
        
        // UserProfile oluştur ve kaydet
        var profile = UserProfile(
            id: currentUser.uid,
            firstName: firstName,
            email: email
        )
        
        profile.purpose = purpose
        profile.schedulingPreference = schedulingPreference
        profile.calendarProvider = calendarProvider
        profile.isOnboardingCompleted = true // ÖNEMLİ!
        
        UserDataManager.shared.saveUserProfile(profile) { success, error in
            DispatchQueue.main.async {
                isSavingProfile = false
                
                if success {
                    print("✅ Onboarding tamamlandı ve profil kaydedildi")
                    showingHomeView = true
                } else {
                    print("❌ Profil kaydetme hatası: \(error?.localizedDescription ?? "")")
                }
            }
        }
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
            .ignoresSafeArea()
            
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
        
        AuthService.shared.login(email: email, password: password) { result in
            Task { @MainActor in
                isLoading = false
                
                switch result {
                case .success(let authResult):
                    print("✅ GİRİŞ BAŞARILI - Mevcut kullanıcı HomeView'e yönlendirilecek")
                    // Firebase auth manager otomatik olarak durumu güncelleyecek
                    // RootView bu değişikliği algılayıp HomeView'e götürecek
                    
                case .failure(let error):
                    alertMessage = getFirebaseErrorMessage(error)
                    showingAlert = true
                    print("❌ Giriş hatası: \(error.localizedDescription)")
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
        
        AuthService.shared.resetPassword(email: email) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    alertMessage = "Şifre sıfırlama bağlantısı \(email) adresine gönderildi."
                case .failure(let error):
                    alertMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
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
