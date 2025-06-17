//
//  TimelyNewApp.swift
//  TimelyNew
//
//  Created by ilsu on 2.06.2025.
//import SwiftUI
// App.swift dosyanızda Firebase import'larını kontrol edin
import SwiftUI
import Firebase
import FirebaseAuth
@main
struct TimelyNewApp: App {
    init() {
        FirebaseApp.configure()
        
        // Debug için her başlatmada oturumu kapat
        #if DEBUG
        try? Auth.auth().signOut()
        print("🔄 Debug mode: User signed out")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
