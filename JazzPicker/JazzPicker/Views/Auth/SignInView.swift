//
//  SignInView.swift
//  JazzPicker
//

import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)

                Text("Jazz Picker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your jazz lead sheet companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(
                    onRequest: { request in
                        authStore.handleSignInWithAppleRequest(request)
                    },
                    onCompletion: { result in
                        authStore.handleSignInWithAppleCompletion(result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .frame(maxWidth: 280)

                if authStore.isLoading {
                    ProgressView()
                }

                if let error = authStore.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignInView()
        .environment(AuthStore())
}
