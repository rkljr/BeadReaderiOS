//
//  BeadModels.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/23/25.
//

import SwiftUI

class Bead: ObservableObject, Identifiable {
    let id: Int
    let colorName: String
    let count: Int
    
    @Published var isRead: Bool = false   // indicates bead has been read

    init(id: Int, colorName: String, count: Int) {
        self.id = id
        self.colorName = colorName
        self.count = count
    }
    
    var defaultColor: Color = .gray
}

struct GridCell: Identifiable {
    let id = UUID()
    let bead: Bead   // reference to the Bead object
}

struct Pattern {
    let name: String
    let columns: Int
    let rows: Int
    let beads: [Bead]
}
    
struct BeadCellView: View {
    @EnvironmentObject var colorCatalog: ColorCatalog

    let cell: GridCell
    let isCurrentBead: Bool

    @ObservedObject var bead: Bead

    init(cell: GridCell, isCurrentBead: Bool) {
        self.cell = cell
        self.isCurrentBead = isCurrentBead
        self._bead = ObservedObject(wrappedValue: cell.bead)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(colorCatalog.color(for: bead.colorName))

            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 0.5)

            if bead.isRead && !isCurrentBead {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
            
            if isCurrentBead {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow, lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.2), value: bead.isRead)
    }
}

// MARK: - Pattern View Model
@MainActor
final class PatternViewModel: ObservableObject {

//    @EnvironmentObject var settingsModel: SettingsModel
    // Source of truth
    @Published var beads: [Bead] = []
    @Published var gridCells: [GridCell] = []
    @Published var pattern: Pattern?
    @Published var columns: Int = 0
    
    // Playback
    @Published var currentBeadIndex: Int = 0
    @Published var isPlaying: Bool = false
    
    let settingsModel: SettingsModel
    
    init(settingsModel: SettingsModel) {
        self.settingsModel = settingsModel

        PlaybackController.shared.playAction = { [weak self] in
            self?.play()
        }

        PlaybackController.shared.pauseAction = { [weak self] in
            self?.pause()
        }
    }

    private var playTask: Task<Void, Never>?
    
    var currentBead: Bead? {
        guard currentBeadIndex >= 0,
              currentBeadIndex < beads.count else {
            return nil
        }
        return beads[currentBeadIndex]
    }
    
    // The visual anchor for scrolling
    var currentCellID: UUID? {
        guard beads.indices.contains(currentBeadIndex) else { return nil }
        let beadID = beads[currentBeadIndex].id
        return gridCells.first { $0.bead.id == beadID }?.id
    }
    
    // Return the list of colors and how many bead of each color
    var colors: [String: Int] {
        var beadColors = [String: Int]()
        
        for bead in self.beads {
            beadColors[bead.colorName, default: 0] += bead.count
        }
        
        return beadColors
    }
    
    var isAtEnd: Bool {
        currentBeadIndex >= beads.count
    }

    var hasCompletedPlayback: Bool {
        !beads.isEmpty && beads.allSatisfy { $0.isRead }
    }

    func loadPattern(_ pattern: Pattern) {
        self.pattern = pattern
        self.columns = pattern.columns
        self.beads = pattern.beads
        buildGrid()
    }

    func loadIfEmpty(_ pattern: Pattern) {
        guard beads.isEmpty else { return }
        loadPattern(pattern)
    }
    
    private func buildGrid() {
        gridCells.removeAll()
        
        var linearCells: [GridCell] = []
        var index = 0
        for bead in self.beads {
            for _ in 0..<bead.count {
                linearCells.append(
                    GridCell(bead: bead)
                )
                index += 1
            }
        }
        
        // 2️⃣ Reorder into right-to-left rows
        guard columns > 0 else {
            gridCells = linearCells
            return
        }

        for rowStart in stride(from: 0, to: linearCells.count, by: columns) {
            let rowEnd = min(rowStart + columns, linearCells.count)
            let row = Array(linearCells[rowStart..<rowEnd])
            gridCells.append(contentsOf: row.reversed())
        }
        
        resetPlayback()
    }
    
    // MARK: - Playback stuff
    enum BeadPlaybackState {
        case unread
        case current
        case read
    }

    func playbackState(for index: Int) -> BeadPlaybackState {
        if index < currentBeadIndex {
            return .read
        } else if index == currentBeadIndex {
            return .current
        } else {
            return .unread
        }
    }


    @MainActor
    func play() {
        guard !isPlaying else { return }
        isPlaying = true

        playTask = Task {
            await playLoop()
        }
    }

    @MainActor
    private func playLoop() async {
        while isPlaying {
            guard currentBeadIndex < beads.count else {
                // 🔚 End of playback
                await AudioManager.shared.playPatternComplete()
                isPlaying = false
                return
            }

            let bead = beads[currentBeadIndex]

            do {
                // String in groups of 10 if the bead count is greater than 10
                if bead.count > 20 {
                    let countCycles = Int(bead.count) / 10
                    let remainderBeads = bead.count % 10
                    var delay = settingsModel.speed * Double(10)

                    for _ in 0..<countCycles {
                        //Play color and count
                        await AudioManager.shared.playBead(bead, count: 10)
                        //Wait for the user to string their bead(s)
                        try await Task.sleep(
                            nanoseconds: UInt64(delay * 1_000_000_000)
                        )
                    }
                    delay = settingsModel.speed * Double(remainderBeads)
                    //Play color and count
                    await AudioManager.shared.playBead(bead, count: remainderBeads)
                    //Wait for the user to string their bead(s)
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                    
                } else {
                    let delay = settingsModel.speed * Double(bead.count)
                    //Play color and count
                    await AudioManager.shared.playBead(bead)

                    //Wait for the user to string their bead(s)
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                }
                
            } catch {
                return
            }

            bead.isRead = true
            currentBeadIndex += 1
        }
    }

    @MainActor
    func pause() {
        isPlaying = false
        playTask?.cancel()
        playTask = nil
    }

    @MainActor
    func resetPlayback() {
        pause()
        beads.forEach { $0.isRead = false }
        currentBeadIndex = 0
    }

    @MainActor
    func togglePlayPause() {
        if isPlaying {
            pause()
            return
        }

        // ▶️ Play pressed
        if hasCompletedPlayback {
            resetPlayback()
        }

        play()
    }
    
    // MARK: - User Interaction with Bead Section
    func userSelectedBead(at bead: Bead) {
//        guard index >= 0 && index < beads.count else { return }
//        print("Bead Selected: \(currentBeadIndex)")
        // Set the current bead
        currentBeadIndex = bead.id
        
        // Mark all beads up to and including the selected one as read
        for i in 0...currentBeadIndex {
            beads[i].isRead = true
        }

        // Mark beads AFTER as unread
        for i in (currentBeadIndex + 1)..<beads.count {
            beads[i].isRead = false
        }
    }
    
}
