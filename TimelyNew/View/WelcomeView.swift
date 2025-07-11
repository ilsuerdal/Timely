import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showOnboarding: Bool
    @Binding var userFirstName: String
    
    @EnvironmentObject var authManager: FirebaseAuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var rememberMe = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - TAM EKRAN
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.4, blue: 0.9),
                        Color(red: 0.6, green: 0.5, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 30) {
                        // Üst boşluk - Status bar için
                        Spacer()
                            .frame(height: 50)
                        
                        // Logo and Title
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 35))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Timely")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Giriş Yap")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.bottom, 40)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email ve şifrenizi girin")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("example@email.com")
                                            .foregroundColor(.gray)
                                    }
                                    .textFieldStyle(TimelyTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("••••••••")
                                            .foregroundColor(.gray)
                                    }
                                    .textFieldStyle(TimelyTextFieldStyle())
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
                                
                                Button(action: forgotPasswordAction) {
                                    Text("Şifremi Unuttum?")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        .padding(.horizontal, 30)
                        
                        // Login Button
                        VStack(spacing: 15) {
                            Button(action: loginAction) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Giriş Yap")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 30)
                            
                            // Social Login Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("veya giriş yap")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 10)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 30)
                            
                            // Apple Sign In
                            Button(action: appleSignInAction) {
                                HStack(spacing: 12) {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18))
                                    Text("Apple ile Giriş Yap")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            .disabled(isLoading)
                            .padding(.horizontal, 30)
                        }
                        
                        // Sign Up Link
                        HStack {
                            Text("Hesabınız yok mu?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: { showSignUp = true }) {
                                Text("Kayıt Ol")
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                        .font(.callout)
                        
                        // Alt boşluk - Home indicator için
                        Spacer()
                            .frame(height: 50)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: UIScreen.main.bounds.height) // Minimum ekran yüksekliği
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: authManager.isLoggedIn) { _, newValue in
            // Firebase AuthManager'dan gelen state değişikliği
            if newValue {
                isAuthenticated = true
                // Onboarding kontrolü
                checkOnboardingStatus()
            }
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
    }
    
    private func loginAction() {
        isLoading = true
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let authResult):
                    print("✅ Email ile giriş başarılı")
                    userFirstName = extractFirstName(from: authResult.user.displayName ?? authResult.user.email ?? "User")
                    checkOnboardingStatus()
                    
                case .failure(let error):
                    alertMessage = getFirebaseErrorMessage(error)
                    showAlert = true
                }
            }
        }
    }
    
    private func appleSignInAction() {
        authManager.signInWithApple { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Apple ile giriş başarılı")
                    if let user = authManager.currentUser {
                        userFirstName = extractFirstName(from: user.displayName ?? user.email ?? "User")
                        checkOnboardingStatus()
                    }
                } else {
                    alertMessage = error?.localizedDescription ?? "Apple ile giriş hatası"
                    showAlert = true
                }
            }
        }
    }
    
    private func forgotPasswordAction() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen önce email adresinizi girin."
            showAlert = true
            return
        }
        
        AuthService.shared.resetPassword(email: email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    alertMessage = "Şifre sıfırlama bağlantısı \(email) adresine gönderildi."
                case .failure(let error):
                    alertMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
                }
                showAlert = true
            }
        }
    }
    
    private func checkOnboardingStatus() {
        // UserDefaults'tan onboarding durumunu kontrol et
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
        showOnboarding = !onboardingCompleted
        
        // Firebase'den de kontrol et (daha güvenilir)
        if let currentUser = authManager.currentUser {
            UserDataManager.shared.getUserProfile(userId: currentUser.uid) { profile, error in
                DispatchQueue.main.async {
                    if let profile = profile {
                        showOnboarding = !profile.isOnboardingCompleted
                    }
                }
            }
        }
    }
    
    private func extractFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "User"
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

// MARK: - Custom Text Field Style
struct TimelyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
            .font(.body)
    }
}

// MARK: - Social Login Button
struct SocialLoginButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView(
        isAuthenticated: .constant(false),
        showOnboarding: .constant(false),
        userFirstName: .constant("")
    )
    .environmentObject(FirebaseAuthManager.shared)
}
