//
//  JazzPickerApp.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

// MARK: - Environment Key for Deep Link Join Code

private struct PendingJoinCodeKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var pendingJoinCode: Binding<String?> {
        get { self[PendingJoinCodeKey.self] }
        set { self[PendingJoinCodeKey.self] = newValue }
    }
}

@main
struct JazzPickerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authStore = AuthStore()
    @StateObject private var userProfileStore = UserProfileStore()
    @StateObject private var catalogStore = CatalogStore()
    @StateObject private var cachedKeysStore = CachedKeysStore()
    @StateObject private var setlistStore = SetlistStore()
    @StateObject private var bandStore = BandStore()
    @StateObject private var grooveSyncStore = GrooveSyncStore()
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var pendingJoinCode: String?

    var body: some Scene {
        WindowGroup {
            AuthGateView {
                ContentView()
            }
            .environmentObject(authStore)
            .environmentObject(userProfileStore)
            .environmentObject(catalogStore)
            .environmentObject(cachedKeysStore)
            .environmentObject(setlistStore)
            .environmentObject(bandStore)
            .environmentObject(grooveSyncStore)
            .environmentObject(PDFCacheService.shared)
            .environmentObject(networkMonitor)
            .environment(\.pendingJoinCode, $pendingJoinCode)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle jazzpicker://join/code
        if url.scheme == "jazzpicker", url.host == "join" {
            let code = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !code.isEmpty {
                pendingJoinCode = code
            }
        }
    }
}
