//
//  PreviewProviders.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/23/25.
//

import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsModel()
        let patternVM = PatternViewModel(settingsModel: settings)
        
        NavigationStack{
            ContentView()
                .environmentObject(settings)
                .environmentObject(patternVM)
                .environmentObject(ColorCatalog.shared)   // inject the catalog
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(SettingsModel.preview)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    @State static var showingSheet = true

    static var previews: some View {
        NavigationStack {
            Color.clear
                .sheet(isPresented: $showingSheet) {
                    AboutView()
                }
        }
    }
}

struct OpenView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OpenView()
        }
    }
}

