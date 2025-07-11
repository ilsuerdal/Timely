// ContactsView.swift - Tam Ekran
import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Kapat") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Kişiler")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Ekle") {
                        // Yeni kişi ekleme fonksiyonu
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                if viewModel.contacts.isEmpty {
                    // Empty state
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz kişi yok")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Toplantılarınızda yer alan kişiler otomatik olarak burada görünecek")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                } else {
                    // Contacts list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.contacts) { contact in
                                ContactRowView(contact: contact)
                                
                                if contact.id != viewModel.contacts.last?.id {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
        }
    }
}

struct ContactRowView: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(String(contact.name.prefix(1)))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(contact.email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("\(contact.meetingCount) toplantı")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Contact actions
            Button(action: {
                // Email gönder
                if let url = URL(string: "mailto:\(contact.email)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "envelope")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
