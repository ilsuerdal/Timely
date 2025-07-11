import Foundation
import SwiftUI


struct FeatureCard: View {
    let icon: String  // SF Symbol veya Emoji
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon (emoji ise emoji, SF Symbol ise renkli icon)
                if isEmoji(icon) {
                    Text(icon)
                        .font(.system(size: 32))
                        .frame(height: 40)
                } else {
                    // SF Symbol ile renkli iconlar (görseldeki gibi)
                    Image(systemName: getIconName(for: icon))
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(getIconColor(for: icon))
                        .frame(height: 40)
                }
                
                // Text content (görseldeki ile aynı)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    private func isEmoji(_ text: String) -> Bool {
        return text.count == 1 && text.unicodeScalars.first?.properties.isEmoji == true
    }
    
    private func getIconName(for icon: String) -> String {
        switch icon {
        case "📅": return "calendar"
        case "⚙️": return "gearshape.fill"
        case "⏰": return "clock.fill"
        case "👥": return "person.2.fill"
        default: return icon
        }
    }
    
    private func getIconColor(for icon: String) -> Color {
        switch icon {
        case "📅", "calendar": return .red
        case "⚙️", "gearshape.fill": return .gray
        case "⏰", "clock.fill": return .red
        case "👥", "person.2.fill": return .blue
        default: return .gray
        }
    }
}

struct ExactImageFeatureCard: View {
    let type: FeatureType
    let action: () -> Void
    
    enum FeatureType {
        case calendar
        case meetingTypes
        case availability
        case contacts
        
        var iconName: String {
            switch self {
            case .calendar: return "calendar"
            case .meetingTypes: return "gearshape.fill"
            case .availability: return "clock.fill"
            case .contacts: return "person.2.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .calendar: return .red
            case .meetingTypes: return .gray
            case .availability: return .red
            case .contacts: return .blue
            }
        }
        
        var title: String {
            switch self {
            case .calendar: return "Takvim"
            case .meetingTypes: return "Toplantı Türleri"
            case .availability: return "Müsaitlik"
            case .contacts: return "Kişiler"
            }
        }
        
        var subtitle: String {
            switch self {
            case .calendar: return "Toplantılarınızı görüntüleyin"
            case .meetingTypes: return "Özel toplantı türleri oluşturun"
            case .availability: return "Çalışma saatlerinizi ayarlayın"
            case .contacts: return "İletişim listenizi yönetin"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Renkli icon (görseldeki ile tam aynı)
                Image(systemName: type.iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(type.iconColor)
                    .frame(height: 40)
                
                // Text content (görseldeki ile tam aynı)
                VStack(spacing: 6) {
                    Text(type.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text(type.subtitle)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}
