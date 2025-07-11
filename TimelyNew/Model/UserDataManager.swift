//
//  UserDataManager.swift
//  TimelyNew
//
//  Created by ilsu on 10.06.2025.
//

import Foundation
import FirebaseFirestore

class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Save User Profile
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Bool, Error?) -> Void) {
        do {
            try db.collection("users").document(profile.id).setData(from: profile) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Profil kaydetme hatası: \(error.localizedDescription)")
                        completion(false, error)
                    } else {
                        print("✅ Profil başarıyla kaydedildi: \(profile.firstName)")
                        completion(true, nil)
                    }
                }
            }
        } catch {
            print("❌ Profil kodlama hatası: \(error.localizedDescription)")
            completion(false, error)
        }
    }
    
    // MARK: - Get User Profile
    func getUserProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profil getirme hatası: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                
                guard let document = document, document.exists else {
                    print("📝 Profil bulunamadı, yeni kullanıcı")
                    completion(nil, nil)
                    return
                }
                
                do {
                    let profile = try document.data(as: UserProfile.self)
                    print("✅ Profil başarıyla yüklendi: \(profile.firstName)")
                    completion(profile, nil)
                } catch {
                    print("❌ Profil decode hatası: \(error.localizedDescription)")
                    completion(nil, error)
                }
            }
        }
    }
    
    // MARK: - Update User Profile
    func updateUserProfile(_ profile: UserProfile, completion: @escaping (Bool, Error?) -> Void) {
        saveUserProfile(profile, completion: completion)
    }
    
    // MARK: - Delete User Profile
    func deleteUserProfile(userId: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profil silme hatası: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("✅ Profil başarıyla silindi")
                    completion(true, nil)
                }
            }
        }
    }
}
