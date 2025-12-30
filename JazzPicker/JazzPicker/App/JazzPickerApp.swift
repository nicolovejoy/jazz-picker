//
//  JazzPickerApp.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

// MARK: - Environment Keys for Deep Links

private struct PendingJoinCodeKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

private struct PendingSetlistIdKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var pendingJoinCode: Binding<String?> {
        get { self[PendingJoinCodeKey.self] }
        set { self[PendingJoinCodeKey.self] = newValue }
    }

    var pendingSetlistId: Binding<String?> {
        get { self[PendingSetlistIdKey.self] }
        set { self[PendingSetlistIdKey.self] = newValue }
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
    @StateObject private var metronomeStore = MetronomeStore()
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var pendingJoinCode: String?
    @State private var pendingSetlistId: String?

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
            .environmentObject(metronomeStore)
            .environmentObject(PDFCacheService.shared)
            .environmentObject(networkMonitor)
            .environment(\.pendingJoinCode, $pendingJoinCode)
            .environment(\.pendingSetlistId, $pendingSetlistId)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "jazzpicker" else { return }

        switch url.host {
        case "join":
            // jazzpicker://join/{code}
            let code = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !code.isEmpty {
                pendingJoinCode = code
            }
        case "setlist":
            // jazzpicker://setlist/{id}
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !id.isEmpty {
                pendingSetlistId = id
            }
        default:
            break
        }
    }
}
