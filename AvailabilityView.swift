//
//  AvailabilityView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct AvailabilityView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Müsaitlik Ayarları")
                    .font(.title)
                    .padding()
                
                // Burada gerçek müsaitlik ayarları formu implementasyonu yapılacak
                
                Spacer()
                
                Button("Kapat") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Müsaitlik")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}
