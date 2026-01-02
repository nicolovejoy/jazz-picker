//
//  LoadingNextChartIndicator.swift
//  JazzPicker
//
//  Loading indicator shown during Groove Sync chart transitions.
//

import SwiftUI

struct LoadingNextChartIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("loading next chart")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    ZStack {
        Color.gray
        LoadingNextChartIndicator()
    }
}
