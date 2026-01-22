//
//  BeadReaderApp.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/23/25.
//

import SwiftUI

@main
struct BeadReaderApp: App {
    
    @StateObject private var settings = SettingsModel()
    @StateObject private var patternViewModel: PatternViewModel
    @StateObject private var colorCatalog = ColorCatalog.shared
    
    init() {
        let settings = SettingsModel()
        _ = ColorCatalog.shared // force load once
        self._settings = StateObject(wrappedValue: settings)
        self._patternViewModel = StateObject(
            wrappedValue: PatternViewModel(settingsModel: settings)
        )
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(settings)
                    .environmentObject(patternViewModel)
                    .environmentObject(colorCatalog)
            }
        }
    }
}
