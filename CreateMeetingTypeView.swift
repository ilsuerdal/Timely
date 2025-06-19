//
//  CreateMeetingTypeView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct CreateMeetingTypeView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Toplantı Türü Oluştur")
                    .font(.title)
                    .padding()
                
                // Burada gerçek toplantı türü oluşturma formu implementasyonu yapılacak
                
                Spacer()
                
                Button("Kapat") {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Yeni Tür")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}
