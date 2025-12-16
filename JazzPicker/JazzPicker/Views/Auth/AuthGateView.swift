//
//  AuthGateView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct AuthGateView<Content: View>: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(BandStore.self) private var bandStore
    @Environment(CachedKeysStore.self) private var cachedKeysStore

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        SwiftUI.Group {
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
        .onChange(of: userProfileStore.profile?.groups) { _, newGroups in
            // Re-subscribe to setlists and reload bands when groups change
            if let uid = authStore.user?.uid {
                setlistStore.startListening(ownerId: uid, groupIds: newGroups)
                Task {
                    await bandStore.loadBands(userId: uid)
                }
            }
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
            // User signed in — start listening to their profile and setlists
            userProfileStore.startListening(uid: uid)
            // Load groups and start setlist listening (groups will update via profile listener)
            Task {
                await bandStore.loadBands(userId: uid)
            }
            // Start listening with current groups (may be nil on first load, will update via onChange)
            let groupIds = userProfileStore.profile?.groups
            setlistStore.startListening(ownerId: uid, groupIds: groupIds)
            // Configure CachedKeysStore to delegate sticky keys to UserProfileStore
            cachedKeysStore.configure(userProfileStore: userProfileStore, authStore: authStore)
        } else if oldUID != nil {
            // User signed out — stop listening and clear data
            userProfileStore.stopListening()
            userProfileStore.clearCache()
            setlistStore.stopListening()
            bandStore.clear()
        }
    }
}

#Preview("Signed Out") {
    AuthGateView {
        Text("Main Content")
    }
    .environment(AuthStore())
    .environment(UserProfileStore())
    .environment(SetlistStore())
    .environment(BandStore())
    .environment(CachedKeysStore())
}
