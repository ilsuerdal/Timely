import SwiftUI

struct CalendarManagerView: View {
    @ObservedObject var authManager = FirebaseAuthManager.shared
    @State private var title = "Timely Meeting"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Etkinlik Başlığı", text: $title)
                .textFieldStyle(.roundedBorder)
            
            DatePicker("Başlangıç", selection: $startDate)
            DatePicker("Bitiş", selection: $endDate)
            
            Button("Google Takvime Ekle") {
                // Google Sign-In olmadığı için geçici mesaj
                print("❌ Google Sign-In henüz aktif değil. Google Calendar erişimi için Google Sign-In gerekli.")
                // Kullanıcıya alert göster
            }
            .padding()
            .background(Color.gray) // Devre dışı görünüm
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

