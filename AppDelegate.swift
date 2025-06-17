
import UIKit
import SwiftUI
import AppAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Ana window oluştur
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // SwiftUI view'ı UIKit'e entegre et
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: - URL Handling for AppAuth
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // AppAuth URL handling
        if GoogleAuthManager.shared.currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url) == true {
            GoogleAuthManager.shared.currentAuthorizationFlow = nil
            return true
        }
        
        return false
    }
}
