//
//  Extension.swift
//  TimelyNew
//
//  Created by ilsu on 20.06.2025.
import SwiftUI

// MARK: - View Extensions
extension View {
    func customplaceholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
