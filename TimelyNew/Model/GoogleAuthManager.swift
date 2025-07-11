import Firebase
import FirebaseAuth
import AuthenticationServices
import Combine
import CryptoKit
import UIKit

class FirebaseAuthManager: NSObject, ObservableObject {
    static let shared = FirebaseAuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var userEmail: String? = nil
    @Published var currentUser: User? = nil
    
    override init() {
        super.init()
        
        // Firebase Auth state listener
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoggedIn = user != nil
                self?.userEmail = user?.email
                
                if let user = user {
                    print("✅ Kullanıcı oturum açmış: \(user.email ?? "Email yok")")
                } else {
                    print("❌ Kullanıcı oturum açmamış")
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    
    func signInWithApple(completion: @escaping (Bool, Error?) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        // Completion handler'ı sakla
        self.appleSignInCompletion = completion
        
        authorizationController.performRequests()
    }
    
    private var appleSignInCompletion: ((Bool, Error?) -> Void)?
    
    // MARK: - Google Sign-In (Placeholder)
    
    func signInWithGoogle(completion: @escaping (Bool, Error?) -> Void) {
        // Google Sign-In henüz implement edilmemiş
        // Bu metod gelecekte Google Sign-In SDK'sı ile implement edilecek
        completion(false, NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In henüz implement edilmemiş"]))
    }
    
    // MARK: - Sign Out
    
    func signOut(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            
            DispatchQueue.main.async {
                print("✅ Çıkış yapıldı")
                completion(true)
            }
        } catch {
            print("❌ Çıkış hatası: \(error)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    // MARK: - User Info
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func getCurrentUserDisplayName() -> String? {
        return Auth.auth().currentUser?.displayName
    }
    
    // MARK: - Private Apple Sign-In Helper Methods
    
    private var currentNonce: String?
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Nonce oluşturulamadı. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign-In Delegates

extension FirebaseAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                print("❌ Nonce bulunamadı")
                appleSignInCompletion?(false, NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nonce bulunamadı"]))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("❌ Apple ID token bulunamadı")
                appleSignInCompletion?(false, NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple ID token bulunamadı"]))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("❌ Token string'e çevrilemedi")
                appleSignInCompletion?(false, NSError(domain: "AppleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Token string'e çevrilemedi"]))
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Firebase Apple Sign-In hatası: \(error.localizedDescription)")
                        self?.appleSignInCompletion?(false, error)
                    } else {
                        print("✅ Apple ile Firebase'e giriş başarılı")
                        
                        // İlk giriş için kullanıcı bilgilerini güncelle
                        if let user = authResult?.user, let fullName = appleIDCredential.fullName {
                            let changeRequest = user.createProfileChangeRequest()
                            let displayName = [fullName.givenName, fullName.familyName]
                                .compactMap { $0 }
                                .joined(separator: " ")
                            
                            if !displayName.isEmpty {
                                changeRequest.displayName = displayName
                                changeRequest.commitChanges { error in
                                    if let error = error {
                                        print("❌ Profil güncelleme hatası: \(error)")
                                    } else {
                                        print("✅ Profil güncellendi: \(displayName)")
                                    }
                                }
                            }
                        }
                        
                        self?.appleSignInCompletion?(true, nil)
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In authorization hatası: \(error.localizedDescription)")
        appleSignInCompletion?(false, error)
    }
}

extension FirebaseAuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("Window bulunamadı")
        }
        return window
    }
}

