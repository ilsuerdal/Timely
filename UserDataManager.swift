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
    
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Bool, Error?) -> Void) {
        do {
            try db.collection("users").document(profile.id).setData(from: profile) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        } catch {
            completion(false, error)
        }
    }
    
    func getUserProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let document = document, document.exists else {
                    completion(nil, nil)
                    return
                }
                
                do {
                    let profile = try document.data(as: UserProfile.self)
                    completion(profile, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
    }
}
