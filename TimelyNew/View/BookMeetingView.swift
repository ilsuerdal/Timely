//
//  BookMeetingView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct BookMeetingView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Toplantı Rezervasyonu")
                    .font(.title)
                    .padding()
                
                // Burada gerçek rezervasyon formu implementasyonu yapılacak
                
                Spacer()
                
                Button("Kapat") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Rezervasyon")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}
