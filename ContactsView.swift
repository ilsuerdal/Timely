//
//  ContactsView.swift
//  TimelyNew
//
//  Created by ilsu on 18.06.2025.
//

import Foundation
import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var viewModel: TimelyViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.contacts) { contact in
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                    
                    Text(contact.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(contact.meetingCount) toplantı")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Kişiler")
        }
    }
}
