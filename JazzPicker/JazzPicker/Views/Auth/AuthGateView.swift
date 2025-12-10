//
//  AuthGateView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct AuthGateView<Content: View>: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserProfileStore.self) private var userProfileStore

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if authStore.isLoading {
                loadingView
            } else if authStore.user == nil {
                SignInView()
            } else if userProfileStore.isLoading && userProfileStore.profile == nil {
                loadingView
            } else if userProfileStore.profile == nil {
                OnboardingView()
            } else {
                content()
            }
        }
        .onAppear {
            authStore.start()
        }
        .onChange(of: authStore.user?.uid, initial: true) { oldUID, newUID in
            handleUserChange(from: oldUID, to: newUID)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func handleUserChange(from oldUID: String?, to newUID: String?) {
        if let uid = newUID {
            // User signed in — start listening to their profile
            userProfileStore.startListening(uid: uid)
        } else if oldUID != nil {
            // User signed out — stop listening and clear profile
            userProfileStore.stopListening()
            userProfileStore.clearCache()
        }
    }
}

#Preview("Signed Out") {
    AuthGateView {
        Text("Main Content")
    }
    .environment(AuthStore())
    .environment(UserProfileStore())
}
