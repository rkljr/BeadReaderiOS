//
//  SettingsModel.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/23/25.
//

import SwiftUI

@MainActor
final class SettingsModel: ObservableObject {

    @AppStorage("playByBead") var playByBead: Bool = false
    @AppStorage("speed") var speed: Double = 1.5
    
    static let preview: SettingsModel = {
        let settings = SettingsModel()
        settings.playByBead = false
        settings.speed = 1.5
        return settings
    }()
}
