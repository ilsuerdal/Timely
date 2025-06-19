//
//  CalendarView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Takvim Görünümü")
                    .font(.title)
                    .padding()
                
                // Burada gerçek takvim görünümü implementasyonu yapılacak
                Spacer()
            }
            .navigationTitle("Takvim")
        }
    }
}
