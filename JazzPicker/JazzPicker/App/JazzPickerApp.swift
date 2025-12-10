//
//  JazzPickerApp.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

@main
struct JazzPickerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var authStore = AuthStore()
    @State private var userProfileStore = UserProfileStore()
    @State private var catalogStore = CatalogStore()
    @State private var cachedKeysStore = CachedKeysStore()
    @State private var setlistStore = SetlistStore()
    @State private var pdfCacheService = PDFCacheService.shared
    @State private var networkMonitor = NetworkMonitor()

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
            .environment(pdfCacheService)
            .environment(networkMonitor)
        }
    }
}
