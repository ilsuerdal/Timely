import Foundation
import Firebase
import FirebaseAuth

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    // MARK: - Email/Password Authentication
    
    func login(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        print("🔵 AuthService.login called")
        print("📧 Email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            print("🔍 AuthService Firebase response:")
            if let error = error {
                print("❌ AuthService Error: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let authResult = authResult else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                return
            }
            
            // Update user profile
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = "\(firstName) \(lastName)"
            
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(authResult))
                }
            }
        }
    }
    
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Current User
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
}
