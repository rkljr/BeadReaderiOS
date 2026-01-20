//
//  BeadReaderIntents.swift
//  BeadReader
//
//  Created by Richard Lincoln on 1/5/26.
//
import AppIntents

// MARK: - Play Intent
struct BeadReaderPlayIntent: AppIntent {

    static var title: LocalizedStringResource = "Play Bead Reader"
    static var description = IntentDescription(
        "Starts playing the current bead pattern."
    )

    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            PlaybackController.shared.play()
        }
        return .result()
    }
}

// MARK: - Pause Intent
struct BeadReaderPauseIntent: AppIntent {

    static var title: LocalizedStringResource = "Pause Bead Reader"
    static var description = IntentDescription(
        "Pauses bead playback."
    )

    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            PlaybackController.shared.pause()
        }
        return .result()
    }
}

// MARK: - Shortcuts

struct BeadReaderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: BeadReaderPlayIntent(),
                phrases: [
                    "\(.applicationName) play",
                    "Play \(.applicationName)"                ],
                shortTitle: "Play",
                systemImageName: "play.fill"
            ),
            AppShortcut(
                intent: BeadReaderPauseIntent(),
                phrases: [
                    "\(.applicationName) pause",
                    "Pause \(.applicationName)"                ],
                shortTitle: "Pause",
                systemImageName: "pause.fill"
            )
        ]
    }
}

