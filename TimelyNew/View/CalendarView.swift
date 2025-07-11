import SwiftUI
import Foundation

struct CalendarView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDayDetail = false
    @State private var showingAddMeeting = false
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header (like in image)
                customHeader
                
                // Calendar Content in ScrollView
                ScrollView {
                    VStack(spacing: 0) {
                        // Calendar Section
                        calendarSection
                        
                        // Today's Meetings Section
                        todaysMeetingsSection
                        
                        // Extra space for bottom
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddMeeting) {
            AddMeetingView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingDayDetail) {
            DayDetailView(selectedDate: selectedDate)
                .environmentObject(viewModel)
        }
        .onAppear {
            setupDateFormatter()
        }
    }
    
    // MARK: - Custom Header (like in image)
    private var customHeader: some View {
        VStack(spacing: 0) {
            // Top header with nav
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("Takvim")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: { showingAddMeeting = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Month Navigation (like in image)
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(monthYearString)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    if calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                        Text("Bu Ay")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // Weekday Header (like in image)
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Calendar Grid (like in image)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    ImprovedCalendarDayCell(
                        date: date,
                        meetings: meetingsForDate(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: Date()),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = date
                        }
                        if !meetingsForDate(date).isEmpty {
                            showingDayDetail = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Today's Meetings Section
    private var todaysMeetingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bugünkü Toplantılar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                if !todaysMeetings.isEmpty {
                    Text("\(todaysMeetings.count) toplantı")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            if todaysMeetings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Bugün toplantınız yok")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button("Toplantı Ekle") {
                        showingAddMeeting = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(todaysMeetings) { meeting in
                        ImprovedMeetingCard(meeting: meeting)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: currentMonth).capitalized
    }
    
    private var weekdaySymbols: [String] {
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }
    
    private var calendarDays: [Date] {
        var days: [Date] = []
        
        // Ayın başını bul
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        
        // Ayın başındaki haftanın başını bul (Pazartesi)
        var startOfWeek = startOfMonth
        while calendar.component(.weekday, from: startOfWeek) != 2 { // 2 = Pazartesi
            startOfWeek = calendar.date(byAdding: .day, value: -1, to: startOfWeek) ?? startOfWeek
        }
        
        // 6 hafta göster (42 gün)
        for i in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                days.append(day)
            }
        }
        
        return days
    }
    
    private var todaysMeetings: [Meeting] {
        return meetingsForDate(Date())
    }
    
    // MARK: - Helper Methods
    
    private func setupDateFormatter() {
        dateFormatter.locale = Locale(identifier: "tr_TR")
    }
    
    private func meetingsForDate(_ date: Date) -> [Meeting] {
        return viewModel.meetings.filter { meeting in
            calendar.isDate(meeting.date, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Improved Calendar Day Cell (like in image)
struct ImprovedCalendarDayCell: View {
    let date: Date
    let meetings: [Meeting]
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Meeting indicators (like in image)
                HStack(spacing: 1) {
                    if meetings.count > 0 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    if meetings.count > 1 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    if meetings.count > 2 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                        Text("+")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .frame(height: 8)
            }
            .frame(width: 44, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.5)
        } else if isToday {
            return .white
        } else if isSelected {
            return .white
        } else {
            return .black
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .blue
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
}

// MARK: - Improved Meeting Card
struct ImprovedMeetingCard: View {
    let meeting: Meeting
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("\(meeting.duration)dk")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(meeting.participantEmail)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: meeting.platform.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text(meeting.platform.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(meeting.meetingType)
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.date)
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    let selectedDate: Date
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let dateFormatter = DateFormatter()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Date Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(dayString)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Meetings List
                if dayMeetings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Bu gün için toplantı yok")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Toplantı Ekle") {
                            // Add meeting for this date
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(dayMeetings) { meeting in
                        MeetingRowView(meeting: meeting)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Günlük Görünüm")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
        .onAppear {
            setupDateFormatter()
        }
    }
    
    private var dayMeetings: [Meeting] {
        viewModel.meetings.filter { meeting in
            Calendar.current.isDate(meeting.date, inSameDayAs: selectedDate)
        }.sorted { $0.date < $1.date }
    }
    
    private var dayString: String {
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: selectedDate).capitalized
    }
    
    private var dateString: String {
        dateFormatter.dateFormat = "d MMMM yyyy"
        return dateFormatter.string(from: selectedDate)
    }
    
    private func setupDateFormatter() {
        dateFormatter.locale = Locale(identifier: "tr_TR")
    }
}

// MARK: - Meeting Row View
struct MeetingRowView: View {
    let meeting: Meeting
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("\(meeting.duration)dk")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Meeting details
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(meeting.participantEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: meeting.platform.icon)
                        .font(.caption)
                    Text(meeting.platform.rawValue)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(meeting.meetingType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.date)
    }
}

#Preview {
    CalendarView()
        .environmentObject(TimelyViewModel())
}
