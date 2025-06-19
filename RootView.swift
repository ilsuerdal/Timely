import SwiftUI
import Firebase
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var isLoading = true
    @State private var showOnboarding = false
    @State private var userProfile: UserProfile?
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if authManager.isLoggedIn { // isAuthenticated yerine isLoggedIn kullanın
                if let profile = userProfile, profile.isOnboardingCompleted {
                    // Kullanıcı giriş yapmış ve onboarding tamamlamış
                    ContentView()
                        .environmentObject(authManager) // AuthManager'ı ContentView'a geçir
                } else {
                    // Kullanıcı giriş yapmış ama onboarding tamamlamamış
                    OnboardingView(
                        showOnboarding: .constant(false),
                        firstName: userProfile?.firstName ?? "Kullanıcı"
                    )
                    .environmentObject(authManager)
                }
            } else {
                // Kullanıcı giriş yapmamış
                AuthenticationView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in // iOS 17+ syntax
            if isLoggedIn {
                loadUserProfile()
            } else {
                userProfile = nil
                isLoading = false
            }
        }
    }
    
    private func checkAuthenticationState() {
        isLoading = true
        
        // Auth state'i kontrol et
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if authManager.isLoggedIn {
                loadUserProfile()
            } else {
                isLoading = false
            }
        }
    }
    
    private func loadUserProfile() {
        guard let currentUser = authManager.currentUser else {
            isLoading = false
            return
        }
        
        UserDataManager.shared.getUserProfile(userId: currentUser.uid) { profile, error in
            DispatchQueue.main.async {
                if let profile = profile {
                    self.userProfile = profile
                    print("✅ Kullanıcı profili yüklendi: \(profile.firstName)")
                } else {
                    print("❌ Kullanıcı profili bulunamadı, yeni profil oluşturulacak")
                    // Yeni profil oluştur
                    self.userProfile = UserProfile(
                        id: currentUser.uid,
                        firstName: currentUser.displayName?.components(separatedBy: " ").first ?? "Kullanıcı",
                        email: currentUser.email ?? ""
                    )
                }
                self.isLoading = false
            }
        }
    }
}

struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                Text("Timely")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Yükleniyor...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo ve başlık
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Timely")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Toplantılarınızı kolayca yönetin")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Giriş butonları
            VStack(spacing: 16) {
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Apple ile Giriş Yap")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                
                Button(action: signInWithGoogle) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.title2)
                        Text("Google ile Giriş Yap")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
        .alert("Giriş Hatası", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signInWithApple() {
        authManager.signInWithApple { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Apple ile giriş başarılı")
                } else {
                    errorMessage = error?.localizedDescription ?? "Apple ile giriş yapılırken bir hata oluştu"
                    showError = true
                    print("❌ Apple giriş hatası: \(errorMessage)")
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        authManager.signInWithGoogle { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Google ile giriş başarılı")
                } else {
                    errorMessage = error?.localizedDescription ?? "Google ile giriş yapılırken bir hata oluştu"
                    showError = true
                    print("❌ Google giriş hatası: \(errorMessage)")
                }
            }
        }
    }
}

// MARK: - UserProfile Model (Eğer yoksa ekleyin)
struct UserProfile: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String = ""
    var email: String
    var phoneNumber: String = ""
    var isOnboardingCompleted: Bool = false
    var createdAt: Date = Date()
    var role: String = ""
    var avatarURL: String = ""
    
    init(id: String, firstName: String, email: String) {
        self.id = id
        self.firstName = firstName
        self.email = email
    }
}

// MARK: - UserDataManager (Eğer yoksa ekleyin)
class UserDataManager {
    static let shared = UserDataManager()
    private init() {}
    
    func getUserProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        // Firebase Firestore'dan kullanıcı profilini getir
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(nil, nil) // Profil bulunamadı
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let profile = try JSONDecoder().decode(UserProfile.self, from: jsonData)
                completion(profile, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Bool, Error?) -> Void) {
        let db = Firestore.firestore()
        
        do {
            let data = try Firestore.Encoder().encode(profile)
            db.collection("users").document(profile.id).setData(data) { error in
                completion(error == nil, error)
            }
        } catch {
            completion(false, error)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FirebaseAuthManager.shared)
}
