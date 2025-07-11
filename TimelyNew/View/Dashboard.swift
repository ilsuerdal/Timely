import SwiftUI

struct DashboardView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Arama ve Profil
                HStack {
                    TextField("Search your meeting types", text: $searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 36, height: 36)
                        .overlay(Text("A").foregroundColor(.white).bold())
                }
                .padding(.horizontal)

                // Başlık
                HStack {
                    Text("Your meeting types")
                        .font(.headline)
                        .padding(.horizontal)
                    Spacer()
                }

                // Toplantı Kartı
                MeetingCard(title: "30 Minute Meeting", subtitle: "One-on-one, 30m, Google Meet")
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationBarHidden(true)
        }
    }
}

struct MeetingCard: View {
    var title: String
    var subtitle: String

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.purple)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Circle()
                .fill(Color.gray)
                .frame(width: 32, height: 32)
                .overlay(Text("A").foregroundColor(.white).bold())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

