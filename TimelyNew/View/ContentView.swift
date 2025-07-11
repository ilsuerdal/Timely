import SwiftUI
import FirebaseAuth

struct ContentView: View {
    // DUPLICATE VARIABLE HATASI DÜZELTİLDİ - sadece bir tane isAuthenticated
    @State private var isAuthenticated = false
    @State private var showOnboarding = false
    @State private var userFirstName = ""
    @State private var isLoading = true
    
    var body: some View {
        SimpleTestTabView()
        Text("TEST ÇALIŞIYOR")
                .font(.largeTitle)
                .foregroundColor(.red)
       // Group {
       //     if isLoading {
      //          SplashView()
        //     } else if !isAuthenticated {
        //         LoginView(isAuthenticated: $isAuthenticated,
        //                 showOnboarding: $showOnboarding,
        //                 userFirstName: $userFirstName)
        //     } else if showOnboarding {
        //         OnboardingView(showOnboarding: $showOnboarding,
        //                       firstName: userFirstName)
        //     } else {
        //         MainTabView()
        //     }
        //   }
        //   .onAppear {
            //       checkAuthenticationStatus()
        //   }
        //   .onChange(of: isAuthenticated) { _ in
            //       // Authentication state değişikliklerini burada handle edebiliriz
        //  }
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

struct SimpleTestTabView: View {
    var body: some View {
        TabView {
            // İlk Tab - Ana Sayfa
            VStack {
                Text("🏠 ANA SAYFA")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("İlk tab çalışıyor!")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Ana Sayfa")
            }
            
            // İkinci Tab - Takvim
            VStack {
                Text("📅 TAKVİM")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Takvim tab çalışıyor!")
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Takvim")
            }
            
            // Üçüncü Tab - Test
            VStack {
                Text("⚙️ AYARLAR")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("Üçüncü tab çalışıyor!")
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Ayarlar")
            }
        }
    }
}




#Preview {
    ContentView()
}
