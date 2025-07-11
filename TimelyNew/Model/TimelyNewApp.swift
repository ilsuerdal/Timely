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
            RootView() // ContentView yerine RootView kullanıyoruz
                .environmentObject(FirebaseAuthManager.shared)
        }
    }
}


