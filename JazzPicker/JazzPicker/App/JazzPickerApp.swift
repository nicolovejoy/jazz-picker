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

    @State private var authStore = AuthStore()
    @State private var userProfileStore = UserProfileStore()
    @State private var catalogStore = CatalogStore()
    @State private var cachedKeysStore = CachedKeysStore()
    @State private var setlistStore = SetlistStore()
    @State private var bandStore = BandStore()
    @State private var pdfCacheService = PDFCacheService.shared
    @State private var networkMonitor = NetworkMonitor()

    @State private var pendingJoinCode: String?

    var body: some Scene {
        WindowGroup {
            AuthGateView {
                ContentView()
            }
            .environment(authStore)
            .environment(userProfileStore)
            .environment(catalogStore)
            .environment(cachedKeysStore)
            .environment(setlistStore)
            .environment(bandStore)
            .environment(pdfCacheService)
            .environment(networkMonitor)
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
