//
//  SimpleEmailLogin.swift
//  TimelyNew
//
//  Created by ilsu on 19.06.2025.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct SimpleEmailLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSignUp = false
    
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
               
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 20) {
                        HStack {
                            Button("İptal") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "envelope.badge")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Timely")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Email ile Giriş")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // Login Form
                    VStack(spacing: 24) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $email)
                                .placeholder(when: email.isEmpty) {
                                    Text("example@email.com")
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Şifre")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("••••••••")
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Şifremi Unuttum?") {
                                resetPassword()
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Login Button
                    VStack(spacing: 20) {
                        Button(action: loginWithEmail) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                        .scaleEffect(0.9)
                                } else {
                                    Text("Giriş Yap")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.purple)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
                        
                        // Sign Up Link
                        HStack {
                            Text("Hesabınız yok mu?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button("Kayıt Ol") {
                                showingSignUp = true
                            }
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .underline()
                        }
                        .font(.system(size: 16))
                    }
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SimpleEmailSignUpView()
            }
            .alert("Bilgi", isPresented: $showingAlert) {
                Button("Tamam") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty && password.count >= 6
    }
    
    private func loginWithEmail() {
        isLoading = true
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let authResult):
                    print("✅ Email ile giriş başarılı: \(authResult.user.email ?? "")")
                    // dismiss() otomatik olarak onChange ile çalışacak
                    
                case .failure(let error):
                    alertMessage = getFirebaseErrorMessage(error)
                    showingAlert = true
                    print("❌ Email giriş hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen önce email adresinizi girin."
            showingAlert = true
            return
        }
        
        AuthService.shared.resetPassword(email: email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    alertMessage = "Şifre sıfırlama bağlantısı \(email) adresine gönderildi."
                case .failure(let error):
                    alertMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    private func getFirebaseErrorMessage(_ error: Error) -> String {
        guard let errorCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return error.localizedDescription
        }
        
        switch errorCode {
        case .userNotFound:
            return "Bu email adresi ile kayıtlı kullanıcı bulunamadı."
        case .wrongPassword:
            return "Hatalı şifre girdiniz."
        case .invalidEmail:
            return "Geçersiz email adresi."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin."
        case .tooManyRequests:
            return "Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin."
        case .userDisabled:
            return "Bu hesap devre dışı bırakılmış."
        default:
            return error.localizedDescription
        }
    }
}


#Preview {
    SimpleEmailLoginView()
}
