//
//  BlankPageView.swift
//  JazzPicker
//
//  Shown in Page 2 mode when leader is on the last page or chart is single page.
//

import SwiftUI

struct BlankPageView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text("this screen intentionally left blank")
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    BlankPageView()
}
