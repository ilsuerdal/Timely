import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TimelyViewModel()
    @State private var showingAddMeeting = false
    @State private var showingCreateMeetingType = false
    @State private var showingAvailability = false
    @State private var showingBookMeeting = false
    @State private var showingCalendar = false
    @State private var showingContacts = false
    @State private var showingProfile = false
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with title, bell and profile icons
                    HStack {
                        Text("Timely")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Bell icon
                            Button(action: {
                                showingNotifications = true
                            }) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            
                            // Profile icon
                            Button(action: {
                                showingProfile = true
                            }) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                    // Feature Cards Grid (EXACTLY like first image with emoji icons)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        
                        // Takvim Card - Calendar emoji like in first image
                        FirstImageFeatureCard(
                            icon: "📅",
                            title: "Takvim",
                            subtitle: "Toplantılarınızı görüntüleyin"
                        ) {
                            showingCalendar = true
                        }
                        
                        // Toplantı Türleri Card - Gear emoji like in first image
                        FirstImageFeatureCard(
                            icon: "⚙️",
                            title: "Toplantı Türleri",
                            subtitle: "Özel toplantı türleri oluşturun"
                        ) {
                            showingCreateMeetingType = true
                        }
                        
                        // Müsaitlik Card - Clock emoji like in first image
                        FirstImageFeatureCard(
                            icon: "⏰",
                            title: "Müsaitlik",
                            subtitle: "Çalışma saatlerinizi ayarlayın"
                        ) {
                            showingAvailability = true
                        }
                        
                        // Kişiler Card - People emoji like in first image
                        FirstImageFeatureCard(
                            icon: "👥",
                            title: "Kişiler",
                            subtitle: "İletişim listenizi yönetin"
                        ) {
                            showingContacts = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    
                    // Hızlı İşlemler Section (exactly like first image)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hızlı İşlemler")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            FirstImageQuickActionRow(
                                icon: "📅",
                                title: "Toplantı Rezervasyonu",
                                subtitle: "Yeni bir toplantı rezerve edin"
                            ) {
                                showingAddMeeting = true
                            }
                            
                            FirstImageQuickActionRow(
                                icon: "➕",
                                title: "Toplantı Türü Oluştur",
                                subtitle: "Özel toplantı türü tanımlayın"
                            ) {
                                showingCreateMeetingType = true
                            }
                            
                            FirstImageQuickActionRow(
                                icon: "🕐",
                                title: "Müsaitlik Ayarla",
                                subtitle: "Çalışma saatlerinizi düzenleyin"
                            ) {
                                showingAvailability = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                    
                    // Bu Ay İstatistikleri Section (updated - no progress bar, colorful stats)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Bu Ay İstatistikleri")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Stats cards with bigger, colorful numbers
                        HStack(spacing: 12) {
                            ColorfulStatCard(
                                title: "Toplantılar",
                                value: "\(viewModel.monthlyStats.meetings)",
                                color: .blue
                            )
                            
                            ColorfulStatCard(
                                title: "Kişiler",
                                value: "\(viewModel.contacts.count)",
                                color: .green
                            )
                            
                            ColorfulStatCard(
                                title: "Saat Tasarrufu",
                                value: "\(viewModel.monthlyStats.hoursSaved)",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddMeeting) {
            AddMeetingView()
                .environmentObject(viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingCreateMeetingType) {
            CreateMeetingTypeView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingAvailability) {
            AvailabilityView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingBookMeeting) {
            BookMeetingView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingContacts) {
            ModernContactsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingProfile) {
            DynamicProfileView()
                .environmentObject(FirebaseAuthManager.shared)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - First Image Feature Card (emoji icons exactly like first image)
struct FirstImageFeatureCard: View {
    let icon: String // Emoji icon
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Emoji icon exactly like first image
                Text(icon)
                    .font(.system(size: 32))
                    .frame(height: 40)
                
                // Text content exactly like first image
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                // Hafif grid pattern overlay (görseldeki gibi)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(
                // İç grid çizgileri
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                        .offset(y: -20)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                        .offset(y: 20)
                }
            )
            .overlay(
                // Dikey grid çizgileri
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 0.5)
                        .padding(.vertical, 20)
                        .offset(x: -20)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 0.5)
                        .padding(.vertical, 20)
                        .offset(x: 20)
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - First Image Quick Action Row (emoji icons exactly like first image)
struct FirstImageQuickActionRow: View {
    let icon: String // Emoji icon
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji icon with background exactly like first image
                Text(icon)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                // Text content exactly like first image
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Arrow exactly like first image
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Colorful Stat Card (bigger, colorful numbers)
struct ColorfulStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Modern Calendar View
struct ModernCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Takvim")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Ekle") {
                        // Add meeting action
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("📅")
                        .font(.system(size: 60))
                    
                    Text("Takvim Görünümü")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Toplantılarınızı buradan görüntüleyebilirsiniz")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Modern Contacts View
struct ModernContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Kişiler")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Ekle") {
                        // Add contact action
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                if viewModel.contacts.isEmpty {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("👥")
                            .font(.system(size: 50))
                        
                        Text("Henüz kişi yok")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Toplantı yaptığınız kişiler burada görünecek")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                } else {
                    List(viewModel.contacts, id: \.id) { contact in
                        ContactRowView(contact: contact)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Profil")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("S")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)
                        )
                    
                    Text("Profil Sayfası")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Profil ayarlarınızı buradan düzenleyebilirsiniz")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
}
