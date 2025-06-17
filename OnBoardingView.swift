import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let firstName: String
    
    @State private var currentPage = 0
    @State private var selectedOption = ""
    @State private var showingAuthErrorAlert = false
    @State private var navigateToCalendar = false
    @State private var isSavingProfile = false
    @State private var showingSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    // Onboarding yanıtlarını saklamak için
    @State private var purpose = ""
    @State private var schedulingPreference = ""
    @State private var calendarProvider = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Welcome, \(firstName)!")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 50)
                
                Group {
                    switch currentPage {
                    case 0:
                        QuestionView(
                            question: "What do you want to use Timely for?",
                            optionsWithIcons: [
                                ("Personal", "person"),
                                ("Work", "briefcase"),
                                ("Both", "person.2")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 1:
                        QuestionView(
                            question: "How do you prefer to schedule meetings?",
                            optionsWithIcons: [
                                ("Manually", "hand.tap"),
                                ("Automatically", "sparkles"),
                                ("Mixed", "slider.horizontal.3")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 2:
                        QuestionView(
                            question: "Set up the calendar that will be used to check for existing events?",
                            optionsWithIcons: [
                                ("Google Calendar", "calendar"),
                                ("Exchange Calendar", "tray.and.arrow.down.fill"),
                                ("Outlook Calendar", "envelope.badge")
                            ],
                            selectedOption: $selectedOption
                        )
                    default:
                        Text("End")
                    }
                }
                
                Spacer()
                
                // Butonlar - son sayfada Apple Sign-In, diğerlerinde Next
                if currentPage < 2 {
                    Button("Continue") {
                        goToNextPageOrFinish()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedOption.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedOption.isEmpty)
                } else {
                    Button(isSavingProfile ? "Saving..." : "Apple ile Devam Et") {
                        startAppleSignIn()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedOption.isEmpty || isSavingProfile ? Color.gray : Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedOption.isEmpty || isSavingProfile)
                }
                
                Spacer()
            }
            .padding()
            .alert("Giriş Hatası", isPresented: $showingAuthErrorAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Apple ile giriş yapma sırasında bir hata oluştu. Lütfen tekrar deneyin.")
            }
            .alert("Kayıt Hatası", isPresented: $showingSaveErrorAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
            .navigationDestination(isPresented: $navigateToCalendar) {
                CalendarManagerView()
            }
        }
    }
    
    private func startAppleSignIn() {
        // Son sayfanın yanıtını kaydet
        saveCurrentPageResponse()
        
        FirebaseAuthManager.shared.signInWithApple { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Apple Sign-In başarılı")
                    self.saveUserProfileToFirebase()
                } else {
                    print("❌ Apple Sign-In hatası: \(error?.localizedDescription ?? "")")
                    self.showingAuthErrorAlert = true
                }
            }
        }
    }
    
    private func saveUserProfileToFirebase() {
        // Firebase Auth'un yüklenmesini bekle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let currentUser = FirebaseAuth.Auth.auth().currentUser else {
                print("❌ Current user bulunamadı, Auth durumu kontrol ediliyor...")
                self.checkAuthStateAndSave()
                return
            }
            
            self.performSaveProfile(with: currentUser)
        }
    }
    
    private func checkAuthStateAndSave() {
        // Handle değişkenini önce tanımla
        var handle: AuthStateDidChangeListenerHandle?
        
        // Auth state listener ekle
        handle = FirebaseAuth.Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("✅ Auth state değişti, kullanıcı bulundu: \(user.uid)")
                self.performSaveProfile(with: user)
                // Listener'ı kaldır
                if let handle = handle {
                    FirebaseAuth.Auth.auth().removeStateDidChangeListener(handle)
                }
            } else {
                DispatchQueue.main.async {
                    self.isSavingProfile = false
                    self.showingSaveErrorAlert = true
                    self.saveErrorMessage = "Giriş yapılmadı. Lütfen tekrar deneyin."
                }
                // Listener'ı kaldır
                if let handle = handle {
                    FirebaseAuth.Auth.auth().removeStateDidChangeListener(handle)
                }
            }
        }
        
        // 5 saniye sonra timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if FirebaseAuth.Auth.auth().currentUser == nil {
                self.isSavingProfile = false
                self.showingSaveErrorAlert = true
                self.saveErrorMessage = "Giriş işlemi zaman aşımına uğradı."
            }
            // Listener'ı kaldır
            if let handle = handle {
                FirebaseAuth.Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
    
    private func performSaveProfile(with currentUser: FirebaseAuth.User) {
        DispatchQueue.main.async {
            self.isSavingProfile = true
            
            // UserProfile oluştur
            var profile = UserProfile(
                id: currentUser.uid,
                firstName: self.firstName,
                email: currentUser.email ?? ""
            )
            
            // Onboarding yanıtlarını ata
            profile.purpose = self.purpose
            profile.schedulingPreference = self.schedulingPreference
            profile.calendarProvider = self.calendarProvider
            profile.isOnboardingCompleted = true
            
            // Firebase'e kaydet
            UserDataManager.shared.saveUserProfile(profile) { success, error in
                DispatchQueue.main.async {
                    self.isSavingProfile = false
                    
                    if success {
                        print("✅ Kullanıcı profili başarıyla kaydedildi")
                        print("📋 Kaydedilen veriler:")
                        print("   - User ID: \(profile.id)")
                        print("   - Purpose: \(profile.purpose)")
                        print("   - Scheduling: \(profile.schedulingPreference)")
                        print("   - Calendar: \(profile.calendarProvider)")
                        self.navigateToCalendar = true
                    } else {
                        print("❌ Profil kaydetme hatası: \(error?.localizedDescription ?? "")")
                        self.saveErrorMessage = "Profil kaydedilirken bir hata oluştu: \(error?.localizedDescription ?? "")"
                        self.showingSaveErrorAlert = true
                    }
                }
            }
        }
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
    
    private func goToNextPageOrFinish() {
        // Mevcut sayfanın yanıtını kaydet
        saveCurrentPageResponse()
        
        if currentPage < 2 {
            currentPage += 1
            selectedOption = ""
        } else {
            showOnboarding = false
        }
    }
}

