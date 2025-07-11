//
//  AuthenticationView..swift
//  TimelyNew
//
//  Created by ilsu on 19.06.2025.
//

import Foundation
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingEmailLogin = false
    @State private var showingEmailSignUp = false
    
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
                
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Logo ve başlık
                    VStack(spacing: 25) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 140, height: 140)
                            
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Timely")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Toplantılarınızı kolayca yönetin")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer()
                    
                    // Giriş butonları
                    VStack(spacing: 16) {
                        // Apple ile giriş
                        Button(action: signInWithApple) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "applelogo")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                Text("Apple ile Giriş Yap")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        
                        // Google ile giriş
                        Button(action: signInWithGoogle) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("Google ile Giriş Yap")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        
                        // Email ile giriş
                        Button(action: { showingEmailLogin = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text("Email ile Giriş Yap")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    // Kayıt ol linki
                    VStack(spacing: 8) {
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Veya")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: { showingEmailSignUp = true }) {
                            Text("Yeni Hesap Oluştur")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingEmailLogin) {
                SimpleEmailLoginView()
            }
            .sheet(isPresented: $showingEmailSignUp) {
                SimpleEmailSignUpView()
            }
            .alert("Giriş Hatası", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signInWithApple() {
        isLoading = true
        
        authManager.signInWithApple { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    print("✅ Apple ile giriş başarılı")
                } else {
                    errorMessage = error?.localizedDescription ?? "Apple ile giriş yapılırken bir hata oluştu"
                    showError = true
                    print("❌ Apple giriş hatası: \(errorMessage)")
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        errorMessage = "Google Sign In yakında eklenecek"
        showError = true
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(FirebaseAuthManager.shared)
}
