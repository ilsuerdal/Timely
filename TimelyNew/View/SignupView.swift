import SwiftUI
import Firebase
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = FirebaseAuthManager.shared
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var agreedToTerms = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - mor tema
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
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 20) {
                            HStack {
                                Button("Geri") {
                                    dismiss()
                                }
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Timely")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Hesap Oluştur")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Name Fields
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Ad")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    TextField("Adınız", text: $firstName)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Soyad")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    TextField("Soyadınız", text: $lastName)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
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
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Şifre")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("En az 6 karakter", text: $password)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Şifre Tekrar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("Şifrenizi tekrar girin", text: $confirmPassword)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)
                            }
                            
                            // Password Requirements
                            if !password.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Şifre gereksinimleri:")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    PasswordRequirement(text: "En az 6 karakter", isValid: password.count >= 6)
                                    PasswordRequirement(text: "En az bir harf", isValid: containsLetter(password))
                                    PasswordRequirement(text: "En az bir rakam", isValid: containsNumber(password))
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            // Terms Agreement
                            HStack(alignment: .top, spacing: 10) {
                                Button(action: { agreedToTerms.toggle() }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                
                                Text("Kullanım şartlarını ve gizlilik politikasını okudum ve kabul ediyorum.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 24)
                        
                        // Sign Up Button
                        Button(action: signUpWithEmail) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                        .scaleEffect(0.9)
                                } else {
                                    Text("Hesap Oluştur")
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
                        .padding(.horizontal, 24)
                        
                        // OR Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("veya")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        
                        // Apple Sign Up
                        Button(action: signUpWithApple) {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18))
                                Text("Apple ile Devam Et")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 24)
                        
                        // Login Link
                        HStack {
                            Text("Zaten hesabınız var mı?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button("Giriş Yap") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .underline()
                        }
                        .font(.system(size: 16))
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        // ← ÖNEMLİ: AuthManager'ın login state'i değiştiğinde dismiss yap
        .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
            if newValue {
                // Kullanıcı başarıyla kayıt oldu ve giriş yaptı
                print("✅ Kayıt başarılı - RootView'a yönlendiriliyor")
                dismiss() // Sheet'i kapat, RootView otomatik olarak onboarding'e yönlendirecek
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email) &&
               password.count >= 6 &&
               containsLetter(password) &&
               containsNumber(password) &&
               password == confirmPassword &&
               agreedToTerms
    }
    
    // MARK: - Private Methods
    
    private func signUpWithEmail() {
        guard isFormValid else {
            showAlert(title: "Hata", message: "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    let errorMessage = getFirebaseErrorMessage(error)
                    showAlert(title: "Kayıt Hatası", message: errorMessage)
                    return
                }
                
                guard let user = authResult?.user else {
                    showAlert(title: "Hata", message: "Kullanıcı oluşturulamadı.")
                    return
                }
                
                // Kullanıcı profilini güncelle
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = "\(firstName) \(lastName)"
                
                changeRequest.commitChanges { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Profil güncelleme hatası: \(error)")
                        } else {
                            print("✅ Profil güncellendi: \(firstName) \(lastName)")
                        }
                        
                        // ← ÖNEMLİ: Kayıt işlemi tamamlandı
                        // onChange(of: authManager.isLoggedIn) otomatik olarak tetiklenecek
                        // ve RootView onboarding'e yönlendirecek
                        print("🚀 Kayıt tamamlandı - AuthManager state güncelleniyor...")
                    }
                }
            }
        }
    }
    
    private func signUpWithApple() {
        authManager.signInWithApple { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Apple ile kayıt başarılı")
                    // onChange(of: authManager.isLoggedIn) otomatik olarak tetiklenecek
                } else {
                    let errorMessage = error?.localizedDescription ?? "Apple ile kayıt hatası"
                    print("❌ Apple kayıt hatası: \(errorMessage)")
                    showAlert(title: "Apple Kayıt Hatası", message: errorMessage)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Validation Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func containsLetter(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .letters) != nil
    }
    
    private func containsNumber(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func getFirebaseErrorMessage(_ error: Error) -> String {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return error.localizedDescription
        }
        
        switch errorCode {
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanımda."
        case .invalidEmail:
            return "Geçersiz e-posta adresi."
        case .weakPassword:
            return "Şifre çok zayıf. Daha güçlü bir şifre seçin."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin."
        case .tooManyRequests:
            return "Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Password Requirement View
struct PasswordRequirement: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .white.opacity(0.6))
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(isValid ? .white : .white.opacity(0.6))
            
            Spacer()
        }
    }
}

#Preview {
    SignUpView()
}
