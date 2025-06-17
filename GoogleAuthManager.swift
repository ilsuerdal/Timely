import AppAuth
import AuthenticationServices
import Combine
import UIKit

class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()
    
    @Published var accessToken: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var userEmail: String? = nil
    
    public var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?
    
    override init() {
        super.init()
        loadSavedAuthState()
    }
    
    func signIn(from presentingViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let issuer = URL(string: "https://accounts.google.com"),
              let redirectURI = URL(string: "com.googleusercontent.apps.411104366070-f46np4u43ksdei391c6ejhfj86j86vbv:/oauthredirect") else {
            print("❌ Geçersiz URL yapılandırması.")
            completion(false)
            return
        }
        
        let clientID = "411104366070-f46np4u43ksdei391c6ejhfj86j86vbv.apps.googleusercontent.com"
        let scopes = [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail, "https://www.googleapis.com/auth/calendar"]
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                print("❌ Config bulma hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                completion(false)
                return
            }
            
            let request = OIDAuthorizationRequest(
                configuration: config,
                clientId: clientID,
                clientSecret: nil,
                scopes: scopes,
                redirectURL: redirectURI,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )
            
            self.currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: request,
                presenting: presentingViewController
            ) { authState, error in
                DispatchQueue.main.async {
                    if let authState = authState {
                        self.authState = authState
                        self.processAuthState(authState)
                        self.saveAuthState()
                        completion(true)
                    } else {
                        print("❌ Yetkilendirme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                        self.clearAuthState()
                        completion(false)
                    }
                }
            }
        }
    }
    
    func signOut() {
        clearAuthState()
        deleteAuthState()
    }
    
    // MARK: - Private Methods
    
    private func processAuthState(_ authState: OIDAuthState) {
        self.accessToken = authState.lastTokenResponse?.accessToken
        self.isLoggedIn = true
        
        fetchUserInfo()
        print("✅ Google Access Token alındı: \(self.accessToken ?? "nil")")
    }
    
    private func clearAuthState() {
        self.authState = nil
        self.accessToken = nil
        self.isLoggedIn = false
        self.userEmail = nil
    }
    
    private func fetchUserInfo() {
        guard let accessToken = accessToken else { return }
        
        let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let email = json["email"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.userEmail = email
            }
        }.resume()
    }
    
    // MARK: - Persistence
    
    private func saveAuthState() {
        guard let authState = authState else { return }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "AuthState")
        } catch {
            print("❌ AuthState kaydetme hatası: \(error)")
        }
    }
    
    private func loadSavedAuthState() {
        guard let data = UserDefaults.standard.data(forKey: "AuthState") else { return }
        
        do {
            if let authState = try NSKeyedUnarchiver.unarchiveObject(with: data) as? OIDAuthState {
                self.authState = authState
                
                // Token hala geçerli mi kontrol et
                if authState.isAuthorized {
                    processAuthState(authState)
                } else {
                    deleteAuthState()
                }
            }
        } catch {
            print("❌ AuthState yükleme hatası: \(error)")
            deleteAuthState()
        }
    }
    
    private func deleteAuthState() {
        UserDefaults.standard.removeObject(forKey: "AuthState")
    }
    
    // Token yenileme
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let authState = authState else {
            completion(false)
            return
        }
        
        authState.performAction { accessToken, idToken, error in
            DispatchQueue.main.async {
                if let accessToken = accessToken {
                    self.accessToken = accessToken
                    completion(true)
                } else {
                    print("❌ Token yenileme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    self.clearAuthState()
                    completion(false)
                }
            }
        }
    }
}
