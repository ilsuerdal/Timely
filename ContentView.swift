import SwiftUI
import FirebaseAuth

struct ContentView: View {
    // GoogleAuthManager'ı kaldırıyoruz, sadece Firebase Auth kullanacağız
    @State private var isAuthenticated = false
    @State private var isAuthenticated = false
    @State private var showOnboarding = false
    @State private var userFirstName = ""
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if !isAuthenticated {
                LoginView(isAuthenticated: $isAuthenticated,
                         showOnboarding: $showOnboarding,
                         userFirstName: $userFirstName)
            } else if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding,
                              firstName: userFirstName)
            } else {
                HomeView()
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
        .onChange(of: isAuthenticated) { _ in
            // Authentication state değişikliklerini burada handle edebiliriz
        }
    }
    
    private func checkAuthenticationStatus() {
        // Firebase Auth state'ini kontrol et
        if let currentUser = Auth.auth().currentUser {
            isAuthenticated = true
            userFirstName = extractFirstName(from: currentUser.displayName ?? currentUser.email ?? "User")
            
            // Onboarding tamamlanmış mı kontrol et
            checkOnboardingStatus()
        } else {
            isAuthenticated = false
            showOnboarding = false
        }
        
        // Loading'i sonlandır
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
    
    private func checkOnboardingStatus() {
        // UserDefaults'tan onboarding durumunu kontrol et
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
        showOnboarding = !onboardingCompleted
    }
    
    private func extractFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "User"
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            // Gradient background (tez görselindeki gibi)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.4, blue: 0.9),
                    Color(red: 0.6, green: 0.5, blue: 0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Timely Logo/Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("Timely")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Zamanınızı Akıllıca Yönetin")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 30)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var showOnboarding: Bool
    @Binding var userFirstName: String
    
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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.4, blue: 0.9),
                        Color(red: 0.6, green: 0.5, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "shield.checkerboard")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                        
                        Text("Timely")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Login")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter your email and password to log in")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("Loisbecket@gmail.com")
                                        .foregroundColor(.gray)
                                }
                                .textFieldStyle(TimelyTextFieldStyle())
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("••••••")
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
                                    Text("Remember me")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Forgot Password?")
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
                                    Text("Log in")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 30)
                        
                        // Social Login Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or login with")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 10)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 30)
                        
                        // Social Login Buttons
                        HStack(spacing: 30) {
                            SocialLoginButton(icon: "g.circle.fill", action: googleSignInAction)
                            SocialLoginButton(icon: "f.circle.fill", action: {})
                            SocialLoginButton(icon: "applelogo", action: {})
                            SocialLoginButton(icon: "square.fill", action: {})
                        }
                    }
                    
                    Spacer()
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: { showSignUp = true }) {
                            Text("Sign Up")
                                .foregroundColor(.white)
                                .bold()
                        }
                    }
                    .font(.callout)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView(isAuthenticated: $isAuthenticated,
                      showOnboarding: $showOnboarding,
                      userFirstName: $userFirstName)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loginAction() {
        isLoading = true
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let authResult):
                    userFirstName = extractFirstName(from: authResult.user.displayName ?? authResult.user.email ?? "User")
                    
                    // Onboarding kontrolü
                    let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
                    showOnboarding = !onboardingCompleted
                    
                    isAuthenticated = true
                    
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func googleSignInAction() {
        // GoogleAuthManager yerine direkt Firebase Auth kullanacağız
        // Şimdilik placeholder
        alertMessage = "Google Sign In will be implemented"
        showAlert = true
    }
    
    private func extractFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "User"
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
    ContentView()
}
