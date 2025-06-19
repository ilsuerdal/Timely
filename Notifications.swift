//
//  Notifications.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Bildirimler Görünümü")
                    .font(.title)
                    .padding()
                
                // Burada gerçek bildirimler listesi implementasyonu yapılacak
                Spacer()
            }
            .navigationTitle("Bildirimler")
        }
    }
}
