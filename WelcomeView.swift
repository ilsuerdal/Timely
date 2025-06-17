import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    var showSignUp: (() -> Void)? = nil
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSignedIn = false
    @State private var showingOnboarding = false
    @State private var currentUserName = ""
    
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Timely")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Remember me and Forgot Password
                        HStack {
                            Button("Forgot Password?") {
                                resetPassword()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Login Button
                    Button(action: loginWithEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Logging in..." : "Log in")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canLogin() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!canLogin() || isLoading)
                    .padding(.horizontal)
                    
                    // OR Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("Or login with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    
                    // Social Login Buttons
                    VStack(spacing: 15) {
                        // Apple Sign In
                        Button(action: signInWithApple) {
                            HStack {
                                Image(systemName: "applelogo")
                                    .font(.title3)
                                Text("Continue with Apple")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading)
                        
                        // Google Sign In
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.title3)
                                Text("Continue with Google")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading)
                        
                        // Facebook Sign In
                        Button(action: signInWithFacebook) {
                            HStack {
                                Image(systemName: "f.square")
                                    .font(.title3)
                                Text("Continue with Facebook")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            if let showSignUp = showSignUp {
                                showSignUp()
                            } else {
                                showingSignUp = true
                            }
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    }
                    .padding(.bottom)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingSignUp) {
           SignUpView(showLogin: {
                showingSignUp = false
            })
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(showOnboarding: $showingOnboarding, firstName: currentUserName)
        }
        .navigationDestination(isPresented: $isSignedIn) {
            HomeView() // Ana uygulama ekranı
        }
        .onAppear {
            checkCurrentUser()
        }
    }
    
    // MARK: - Helper Functions
    
    private func canLogin() -> Bool {
        return !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            print("✅ Kullanıcı zaten giriş yapmış: \(user.email ?? "No email")")
            currentUserName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
            isSignedIn = true
        }
    }
    
    // MARK: - Email/Password Login
    
    private func loginWithEmail() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = "Login failed: \(error.localizedDescription)"
                    showingAlert = true
                    print("❌ Email login error: \(error)")
                } else if let user = result?.user {
                    print("✅ Email login successful: \(user.email ?? "")")
                    currentUserName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
                    
                    // Onboarding tamamlanmış mı kontrol et
                    checkUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    private func checkUserProfile(userId: String) {
        UserDataManager.shared.getUserProfile(userId: userId) { profile, error in
            DispatchQueue.main.async {
                if let profile = profile, profile.isOnboardingCompleted {
                    // Onboarding tamamlanmış, ana ekrana git
                    isSignedIn = true
                } else {
                    // Onboarding henüz tamamlanmamış
                    showingOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Password Reset
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address first."
            showingAlert = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Reset failed: \(error.localizedDescription)"
                } else {
                    alertMessage = "Password reset email sent to \(email)"
                }
                showingAlert = true
            }
        }
    }
    
    // MARK: - Social Login Methods
    
    private func signInWithApple() {
        isLoading = true
        
        FirebaseAuthManager.shared.signInWithApple { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    if let user = Auth.auth().currentUser {
                        currentUserName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User"
                        checkUserProfile(userId: user.uid)
                    }
                } else {
                    alertMessage = "Apple Sign-In failed: \(error?.localizedDescription ?? "Unknown error")"
                    showingAlert = true
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        // Google Sign-In implementation
        alertMessage = "Google Sign-In will be implemented soon"
        showingAlert = true
    }
    
    private func signInWithFacebook() {
        // Facebook Sign-In implementation
        alertMessage = "Facebook Sign-In will be implemented soon"
        showingAlert = true
    }
}
