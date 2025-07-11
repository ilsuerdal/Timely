import SwiftUI

struct CalendarManagerView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @State private var showingMainApp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Takvim Ayarları")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 50)
                
                Text("Takvim entegrasyonunuz başarıyla kuruldu!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    CalendarStatusCard(
                        title: "Takvim Bağlantısı",
                        status: "Aktif",
                        description: "Mevcut etkinlikleriniz kontrol edilecek"
                    )
                    
                    CalendarStatusCard(
                        title: "Senkronizasyon",
                        status: "Hazır",
                        description: "Yeni toplantılar otomatik olarak eklenecek"
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Uygulamaya Başla") {
                    showingMainApp = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingMainApp) {
            ContentView()
        }
    }
}

struct CalendarStatusCard: View {
    let title: String
    let status: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    CalendarManagerView()
        .environmentObject(TimelyViewModel())
}
