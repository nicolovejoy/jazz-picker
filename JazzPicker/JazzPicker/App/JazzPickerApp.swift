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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(catalogStore)
        }
    }
}
