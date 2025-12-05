//
//  JazzPickerApp.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

@main
struct JazzPickerApp: App {
    @State private var catalogStore = CatalogStore()
    @State private var cachedKeysStore = CachedKeysStore()
    @State private var setlistStore = SetlistStore()
    @State private var pdfCacheService = PDFCacheService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(catalogStore)
                .environment(cachedKeysStore)
                .environment(setlistStore)
                .environment(pdfCacheService)
        }
    }
}
