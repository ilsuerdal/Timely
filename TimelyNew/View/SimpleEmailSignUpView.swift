//
//  SimpleEmailSignUpView.swift
//  TimelyNew
//
//  Created by ilsu on 19.06.2025.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

struct SimpleEmailSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = FirebaseAuthManager.shared
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var agreedToTerms = false
    
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
              
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 20) {
                            HStack {
                                Button("Geri") {
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
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Timely")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Hesap Oluştur")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Name Fields
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Ad")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    TextField("", text: $firstName)
                                        .placeholder(when: firstName.isEmpty) {
                                            Text("Adınız")
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Soyad")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    TextField("", text: $lastName)
                                        .placeholder(when: lastName.isEmpty) {
                                            Text("Soyadınız")
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)
                                }
                            }
                            
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
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Şifre Tekrar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                SecureField("", text: $confirmPassword)
                            }
                        }
                    }
                }
            }
        }
    }
}

