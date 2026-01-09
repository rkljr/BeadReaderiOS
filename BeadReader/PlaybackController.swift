//
//  PlaybackController.swift
//  BeadReader
//
//  Created by Richard Lincoln on 1/5/26.
//
import Foundation
import SwiftUI

@MainActor
final class PlaybackController: ObservableObject {
    static let shared = PlaybackController()

    @Published var isPlaying = false

    var playAction: (() -> Void)?
    var pauseAction: (() -> Void)?

    func play() {
        isPlaying = true
        playAction?()
    }

    func pause() {
        isPlaying = false
        pauseAction?()
    }
}
