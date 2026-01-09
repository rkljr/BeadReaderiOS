import AVFoundation

@MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {

    static let shared = AudioManager()

    private var player: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?

    // MARK: - Public API

    func playBead(_ bead: Bead) async {
        await playSoundAsync(named: bead.colorName.lowercased(),
                             subdirectory: "Sounds/colors")

        try? await Task.sleep(nanoseconds: 400_000_000)

        await playSoundAsync(named: String(bead.count),
                             subdirectory: "Sounds/numbers")
    }

    func playBead(_ bead: Bead, count: Int) async {
        await playSoundAsync(named: bead.colorName.lowercased(),
                             subdirectory: "Sounds/colors")

        try? await Task.sleep(nanoseconds: 400_000_000)

        await playSoundAsync(named: String(count),
                             subdirectory: "Sounds/numbers")
    }
    
    func playPatternComplete() async {
        await playSoundAsync(named: "patterncomplete", subdirectory: "Sounds")
    }

    // MARK: - Core async playback

    private func playSoundAsync(
        named name: String,
        subdirectory: String?
    ) async {
        // 🔒 Ensure previous sound is finished
        stopCurrentPlaybackIfNeeded()

        await withCheckedContinuation { continuation in
            self.continuation = continuation

            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: "mp3",
                subdirectory: subdirectory
            ) else {
                // ✅ resume on failure
                continuation.resume()
                self.continuation = nil
                return
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                self.player = player
                player.delegate = self
                player.prepareToPlay()

                if !player.play() {
                    // ✅ resume if playback fails
                    continuation.resume()
                    self.continuation = nil
                }
            } catch {
                print("play error: \(error)")
                // ✅ resume on error
                continuation.resume()
                self.continuation = nil
            }
        }
    }

    private func stopCurrentPlaybackIfNeeded() {
        if let continuation {
            continuation.resume()
            self.continuation = nil
        }

        player?.stop()
        player = nil
    }

    // MARK: - Delegate

    nonisolated func audioPlayerDidFinishPlaying(
        _ audioPlayer: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            guard audioPlayer === player else { return }

            continuation?.resume()
            continuation = nil
            player = nil
        }
    }
}

