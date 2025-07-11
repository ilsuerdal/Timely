import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let firstName: String
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer = ""
    @State private var answers: [String] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var textFieldAnswer = "" // Text input için
    
    // Profil için güncellenmiş sorular
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
                
                VStack(spacing: 40) {
                    // Progress Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Soru \(currentQuestionIndex + 1) / \(questions.count)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                        }
                        
                        ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Welcome Message (sadece ilk soruda)
                    if currentQuestionIndex == 0 {
                        VStack(spacing: 8) {
                            Text("Hoş geldiniz, \(firstName)!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Profilinizi oluşturmak için birkaç soru sormak istiyoruz")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Soru Ekranı
                    VStack(spacing: 30) {
                        // Soru Başlığı
                        Text(questions[currentQuestionIndex].title)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Soru Tipi
                        if questions[currentQuestionIndex].type == .multipleChoice {
                            // Çoktan Seçmeli Seçenekler
                            VStack(spacing: 16) {
                                ForEach(questions[currentQuestionIndex].options, id: \.0) { option, icon in
                                    Button(action: {
                                        selectedAnswer = option
                                        textFieldAnswer = option
                                    }) {
                                        HStack(spacing: 16) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill(selectedAnswer == option ? Color.white : Color.white.opacity(0.2))
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(selectedAnswer == option ? .purple : .white)
                                            }
                                            
                                            // Text
                                            Text(option)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            // Checkmark
                                            if selectedAnswer == option {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedAnswer == option ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                                .stroke(selectedAnswer == option ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // Text Input
                            VStack(spacing: 16) {
                                if questions[currentQuestionIndex].isLongText {
                                    // Uzun metin için TextEditor
                                    ZStack(alignment: .topLeading) {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.1))
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            .frame(height: 120)
                                        
                                        if textFieldAnswer.isEmpty {
                                            Text(questions[currentQuestionIndex].placeholder)
                                                .foregroundColor(.white.opacity(0.6))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                        }
                                        
                                        TextEditor(text: $textFieldAnswer)
                                            .foregroundColor(.white)
                                            .background(Color.clear)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                    }
                                } else {
                                    // Kısa metin için TextField
                                    TextField(questions[currentQuestionIndex].placeholder, text: $textFieldAnswer)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.1))
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                        .font(.system(size: 18))
                                        .accentColor(.white)
                                }
                            }
                            .padding(.horizontal, 24)
                            .onChange(of: textFieldAnswer) { _, newValue in
                                selectedAnswer = newValue
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Finish Button
                    VStack(spacing: 16) {
                        Button(action: handleNextButton) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                        .scaleEffect(0.9)
                                } else {
                                    Text(currentQuestionIndex == questions.count - 1 ? "Profili Oluştur" : "Devam Et")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.purple)
                                    
                                    if currentQuestionIndex < questions.count - 1 {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(selectedAnswer.isEmpty || isLoading)
                        .opacity(selectedAnswer.isEmpty ? 0.6 : 1.0)
                        .padding(.horizontal, 24)
                        
                        // Skip Button (sadece son soru değilse ve text input değilse)
                        if currentQuestionIndex < questions.count - 1 && questions[currentQuestionIndex].type == .multipleChoice {
                            Button("Atla") {
                                selectedAnswer = "Belirtilmedi"
                                textFieldAnswer = "Belirtilmedi"
                                handleNextButton()
                            }
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .alert("Hata", isPresented: $showingAlert) {
                Button("Tamam") { }
            } message: {
                Text(alertMessage)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            // İlk soruya geçerken değerleri sıfırla
            if currentQuestionIndex == 0 {
                selectedAnswer = ""
                textFieldAnswer = ""
            }
        }
    }
    
    private func handleNextButton() {
        // Cevabı kaydet
        let answerToSave = textFieldAnswer.isEmpty ? selectedAnswer : textFieldAnswer
        
        if answers.count <= currentQuestionIndex {
            answers.append(answerToSave)
        } else {
            answers[currentQuestionIndex] = answerToSave
        }
        
        // Son soru mu?
        if currentQuestionIndex == questions.count - 1 {
            // Profili database'e kaydet
            saveProfileToDatabase()
        } else {
            // Sonraki soruya geç
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex += 1
                selectedAnswer = ""
                textFieldAnswer = ""
            }
        }
    }
    
    private func saveProfileToDatabase() {
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = "Kullanıcı bilgisi bulunamadı."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // Temel UserProfile oluştur (mevcut sistem ile uyumlu)
        var basicProfile = UserProfile(
            id: currentUser.uid,
            firstName: firstName,
            email: currentUser.email ?? ""
        )
        
        // Cevapları profile'a ata
        basicProfile.purpose = answers.count > 0 ? answers[0] : ""
        basicProfile.schedulingPreference = answers.count > 4 ? answers[4] : ""
        basicProfile.isOnboardingCompleted = true
        
        // Ek profil bilgilerini UserDefaults'a kaydet (gelecekte Firebase'e taşınabilir)
        let profileExtensions: [String: String] = [
            "title": answers.count > 1 ? answers[1] : "",
            "department": answers.count > 2 ? answers[2] : "",
            "bio": answers.count > 3 ? answers[3] : "",
            "onboardingDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Profili Firebase'e kaydet
        UserDataManager.shared.saveUserProfile(basicProfile) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    // Ek bilgileri UserDefaults'a kaydet
                    UserDefaults.standard.set(profileExtensions, forKey: "ProfileExtensions_\(currentUser.uid)")
                    UserDefaults.standard.set(true, forKey: "onboarding_completed")
                    
                    print("✅ Kullanıcı profili ve ek bilgiler başarıyla kaydedildi")
                    print("📋 Kaydedilen veriler:")
                    print("   - User ID: \(basicProfile.id)")
                    print("   - Purpose: \(basicProfile.purpose)")
                    print("   - Scheduling: \(basicProfile.schedulingPreference)")
                    print("   - Title: \(profileExtensions["title"] ?? "")")
                    print("   - Department: \(profileExtensions["department"] ?? "")")
                    print("   - Bio: \(profileExtensions["bio"] ?? "")")
                    
                    // Notification gönder - RootView'daki extension'ı kullan
                    NotificationCenter.default.post(name: Notification.Name("onboardingCompleted"), object: nil)
                    
                    // Ana ekrana yönlendir
                    self.showOnboarding = false
                    
                } else {
                    print("❌ Profil kaydetme hatası: \(error?.localizedDescription ?? "")")
                    self.alertMessage = "Veriler kaydedilirken bir hata oluştu. Lütfen tekrar deneyin."
                    self.showingAlert = true
                }
            }
        }
    }
}

// MARK: - OnboardingQuestion Model (Unique name to avoid conflicts)
struct OnboardingQuestion {
    let title: String
    let type: OnboardingQuestionType
    let options: [(String, String)] // (text, icon) - sadece multipleChoice için
    let placeholder: String // sadece textInput için
    let isLongText: Bool // uzun metin alanı için
    
    init(title: String, type: OnboardingQuestionType, options: [(String, String)] = [], placeholder: String = "", isLongText: Bool = false) {
        self.title = title
        self.type = type
        self.options = options
        self.placeholder = placeholder
        self.isLongText = isLongText
    }
}

// MARK: - OnboardingQuestionType Enum (Unique name to avoid conflicts)
enum OnboardingQuestionType {
    case multipleChoice
    case textInput
}

#Preview {
    OnboardingView(showOnboarding: .constant(true), firstName: "İlsu")
}
