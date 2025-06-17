import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - Sign Up View
struct SignUpView: View {
    let showLogin: () -> Void
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var birthDate = Date()
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showDatePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var showingOnboarding = false
    @State private var navigateToApp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.68, green: 0.85, blue: 1.0),
                        Color(red: 0.85, green: 0.92, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            HStack {
                                Button(action: showLogin) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            Text("Timely")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Text("Sign Up")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Already have an account? Login")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .onTapGesture { showLogin() }
                        }
                        .padding(.bottom, 30)
                        
                        // Form Section
                        VStack(spacing: 20) {
                            // Name Fields
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("First Name")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    CustomTextField(
                                        placeholder: "Lois",
                                        text: $firstName
                                    )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Last Name")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    CustomTextField(
                                        placeholder: "Becket",
                                        text: $lastName
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                CustomTextField(
                                    placeholder: "Loisbecket@gmail.com",
                                    text: $email,
                                    keyboardType: .emailAddress
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Birth Date Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Birth of Date")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Button(action: { showDatePicker.toggle() }) {
                                    HStack {
                                        Text(birthDate.formatted(date: .abbreviated, time: .omitted))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .sheet(isPresented: $showDatePicker) {
                                    DatePickerSheet(selectedDate: $birthDate)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Phone Number Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Phone Number")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    // Country Code
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(.red)
                                        Text("+")
                                            .foregroundColor(.primary)
                                        Text("(454) 726-0562")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Set Password")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                CustomSecureField(
                                    placeholder: "••••••••",
                                    text: $password
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Password Requirements
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password must contain:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    PasswordRequirement(text: "At least 6 characters", isValid: password.count >= 6)
                                    PasswordRequirement(text: "At least one letter", isValid: containsLetter(password))
                                    PasswordRequirement(text: "At least one number", isValid: containsNumber(password))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Register Button
                            Button(action: register) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("Register")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !isFormValid)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // Social Sign Up
                            VStack(spacing: 16) {
                                // Or sign up with
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                    
                                    Text("Or sign up with")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.horizontal, 20)
                                
                                // Apple Sign-In
                                Button(action: signUpWithApple) {
                                    HStack {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: 18))
                                        Text("Sign up with Apple")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(showOnboarding: $showingOnboarding, firstName: firstName)
        }
        .navigationDestination(isPresented: $navigateToApp) {
            HomeView() // Ana uygulama
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email) &&
               password.count >= 6 &&
               containsLetter(password) &&
               containsNumber(password)
    }
    
    // MARK: - Private Methods
    
    private func register() {
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
                        
                        // Başarılı kayıt - Onboarding'e yönlendir
                        print("🚀 Onboarding'e yönlendiriliyor...")
                        showingOnboarding = true
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
                    
                    // Apple Sign-In sonrası onboarding'e yönlendir
                    if let user = Auth.auth().currentUser {
                        let displayName = user.displayName ?? "User"
                        let nameComponents = displayName.components(separatedBy: " ")
                        firstName = nameComponents.first ?? "User"
                        
                        print("🚀 Apple kullanıcısı onboarding'e yönlendiriliyor...")
                        showingOnboarding = true
                    }
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
        showAlert = true
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



#Preview {
    SignUpView(showLogin: {})
}
