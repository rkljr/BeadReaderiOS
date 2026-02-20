//
//  ContentView.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/23/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var patternViewModel: PatternViewModel
    @EnvironmentObject var colorCatalog: ColorCatalog
    
    @State private var showOpenSheet = false
    @State private var showOpenFilesSheet = false
    @State private var showAboutSheet = false
    @State private var showSettingsSheet = false
    @State private var showColorsSheet = false
    @State private var didLoad = false
    @State private var isPlaying = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        ZStack {
            // Full screen background
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // MARK: - Header / Menu
                HStack {
                    Menu {
                        Button {
                            showOpenSheet = true
                        } label: { Label("Open Photo", systemImage: "photo") }
                        
                        Button {
                            showOpenFilesSheet = true
                        } label: { Label("Open File", systemImage: "folder") }
                        
                        Button {
                            showColorsSheet = true
                        } label: { Label("Pattern Colors", systemImage: "paintpalette.fill") }
                        
                        Button {
                            showSettingsSheet = true
                        } label: { Label("Settings", systemImage: "gear") }
                        
                        Divider()
                        
                        Button {
                            showAboutSheet = true
                        } label: { Label("About", systemImage: "info.circle") }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .padding(.leading)
                    }
                    
                    Spacer()
                    
                    Text(patternViewModel.pattern?.name ?? "BeadReader™")
                        .font(.headline)
                        .padding(.trailing)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // MARK: - Pattern Grid (fills remaining space)
                ZStack {
                    PatternGridView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    PlaybackOverlay()
                }
            }
        }
        .sheet(isPresented: $showOpenSheet) { PhotoPickerSheet(selectedFileURL: $selectedFileURL) }
//        .onChange(of: selectedPhotoURL) { newURL in
//            guard let url = newURL else { return }
//            loadPattern(from: url)
//        }
        .sheet(isPresented: $showOpenFilesSheet) { DocumentPickerView(selectedFileURL: $selectedFileURL) }
        .onChange(of: selectedFileURL) { newURL in
            guard let url = newURL else { return }
            loadPattern(from: url)
        }
        .sheet(isPresented: $showColorsSheet) { NavigationStack { ColorsView() } }
        .sheet(isPresented: $showSettingsSheet) { NavigationStack { SettingsView().environmentObject(settings) } }
        .sheet(isPresented: $showAboutSheet) { NavigationStack { AboutView() } }
        .onAppear { loadDefaultPatternIfNeeded() }
    }

    private func loadDefaultPatternIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        let beads = [
            Bead(id: 0, colorName: "PURPLE", count: 1),
            Bead(id: 1, colorName: "AQUA", count: 9),
            Bead(id: 2, colorName: "PURPLE", count: 1),
            Bead(id: 3, colorName: "AQUA", count: 9),
            Bead(id: 4, colorName: "PURPLE", count: 1),
            Bead(id: 5, colorName: "AQUA", count: 9),
            Bead(id: 6, colorName: "PURPLE", count: 1),
            Bead(id: 7, colorName: "AQUA", count: 1),
            Bead(id: 8, colorName: "PURPLE", count: 1),
            Bead(id: 9, colorName: "AQUA", count: 7),
            Bead(id: 10, colorName: "PURPLE", count: 1),
            Bead(id: 11, colorName: "AQUA", count: 7),
            Bead(id: 12, colorName: "PURPLE", count: 1),
            Bead(id: 13, colorName: "AQUA", count: 1),
            Bead(id: 14, colorName: "PURPLE", count: 1),
            Bead(id: 15, colorName: "AQUA", count: 9),
            Bead(id: 16, colorName: "PURPLE", count: 1),
            Bead(id: 17, colorName: "AQUA", count: 9),
            Bead(id: 18, colorName: "PURPLE", count: 1),
            Bead(id: 19, colorName: "AQUA", count: 9),
            Bead(id: 20, colorName: "PURPLE", count: 1)
        ]

        let pattern = Pattern(name: "BeadReader™", columns: 9, rows: 9, beads: beads)
        patternViewModel.loadIfEmpty(pattern)
    }
    
    private func loadPattern(from url: URL) {
        PatternLoader().loadPNGPattern(from: url) { pattern in
            guard let pattern = pattern else { return }
            DispatchQueue.main.async {
                // Update the patternViewModel
                patternViewModel.loadPattern(pattern)
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @EnvironmentObject var patternViewModel: PatternViewModel

    var body: some View {
        HStack(spacing: 10) {
            Button {
                patternViewModel.togglePlayPause()
            } label: {
                Image(systemName: patternViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
            }

            Text("# \(patternViewModel.currentBeadIndex)")
                .font(.body)

            Button {
                patternViewModel.resetPlayback()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 22))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - PatternGridView Section
struct PatternGridView: View {
    @EnvironmentObject var patternViewModel: PatternViewModel

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 2),
            count: max(patternViewModel.columns, 1)
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: gridColumns,spacing: 1) {
                        ForEach(patternViewModel.gridCells) { cell in
                            BeadCellView(
                                cell: cell,
                                isCurrentBead: cell.bead === patternViewModel.currentBead
                            )
                            .id(cell.id)
                            .onTapGesture {
                                if !patternViewModel.isPlaying {
                                    patternViewModel.userSelectedBead(at: cell.bead)
                                }
                            }
                        }
                    }
            }
            .onChange(of: patternViewModel.currentCellID) { id in
                guard let id else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Play Controls Overlay
struct PlaybackOverlay: View {
    @EnvironmentObject var patternViewModel: PatternViewModel

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 20) {
                Button {
                    patternViewModel.togglePlayPause()
                } label: {
                    Image(systemName: patternViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                }

                Text("# \(patternViewModel.currentBeadIndex)")
                    .font(.body)
                
                HStack(spacing: 3) {
                    Image(systemName: "hourglass")
                    Text("\(patternViewModel.timeRemaining)")
                        .font(.body)
                }
                
                Button {
                    patternViewModel.resetPlayback()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 8)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Setting View
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsModel

    var body: some View {
        Form {

            Section("Playback") {

//                Toggle("Play by Bead", isOn: $settings.playByBead)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed")
                        .font(.headline)

                    Slider(
                        value: Binding(
                            get: { Double(settings.speed) },
                            set: { settings.speed = Double($0) }
                        ),
                        in: 1...10,
                        step: 0.5
                    )

                    Text("Speed: \(settings.speed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}


// MARK: - Open View
//struct OpenView: View {
//
//    @Environment(\.dismiss) private var dismiss
//    @EnvironmentObject var patternViewModel: PatternViewModel
//
//    @State private var showingPhotoPicker = false
//    @State private var selectedFileURL: URL?
//
//    var body: some View {
//        // Minimal placeholder while the picker is open
//        Color.clear
//            .onAppear {
//                // Immediately present the PhotoPicker when the view appears
//                showingPhotoPicker = true
//            }
//            .sheet(isPresented: $showingPhotoPicker) {
//                PhotoPickerSheet(selectedFileURL: $selectedFileURL)
//            }
//            .onChange(of: selectedFileURL) { newURL in
//                guard let url = newURL else {
//                    // User cancelled, just dismiss OpenView
//                    dismiss()
//                    return
//                }
//
//                loadPattern(from: url)
//            }
//    }
//
//    private func loadPattern(from url: URL) {
//        PatternLoader().loadPattern(from: url) { pattern in
//            guard let pattern = pattern else { return }
//            DispatchQueue.main.async {
//                // Update the patternViewModel
//                patternViewModel.loadPattern(pattern)
//                // Close OpenView
//                dismiss()
//            }
//        }
//    }
//}

// MARK: - Document Picker
struct DocumentPickerView: UIViewControllerRepresentable {

    @Binding var selectedFileURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            //forOpeningContentTypes: [.beadPattern], // Only allow xbp files
            forOpeningContentTypes: [.png], // Only allow xbp files
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFileURL = url
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Optional: handle cancel
        }
    }
}

// MARK: - Photo Picker View
struct PhotoPickerSheet: UIViewControllerRepresentable {

    @Binding var selectedFileURL: URL?
    @Environment(\.dismiss) private var dismissSheet

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPickerSheet

        init(_ parent: PhotoPickerSheet) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Always dismiss the picker sheet, whether selection or cancel
            parent.dismissSheet()

            guard let itemProvider = results.first?.itemProvider else {
                // User cancelled, no file selected
                return
            }

            let typeId = UTType.image.identifier

            itemProvider.loadFileRepresentation(forTypeIdentifier: typeId) { url, error in
                if let error = error {
                    print("PhotoPicker error: \(error)")
                    return
                }
                guard let url = url else { return }

                // Copy to temp folder
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)

                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    DispatchQueue.main.async {
                        self.parent.selectedFileURL = tempURL
                    }
                } catch {
                    print("Failed to copy photo to temp file: \(error)")
                }
            }
        }
    }
}



// MARK: - About View
struct AboutView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                Text("BeadReader")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("This app helps you string bead patterns for bead crochet projects quickly and easily.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                
                Text("BeadReader does not collect, store, or share any personal information or usage data. The app does not track users, use analytics, or connect to external servers. Because no data is collected, BeadReader is safe for users of all ages.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                
                Link("Read the full privacy policy", destination: URL(string: "https://rkljr.github.io/privacy-policy.html")!)
                    .font(.body)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
        }
        //.scrollIndicators(.visible)
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - View for showing the colors in a pattern
struct ColorsView: View {
    @EnvironmentObject var patternViewModel: PatternViewModel
    @EnvironmentObject var colorCatalog: ColorCatalog
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        List {
            ForEach(sortedColors, id: \.key) { colorName, count in
                HStack(spacing: 12) {
                    
                    // Color tile
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorCatalog.color(for: colorName))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black, lineWidth: 0.5)
                        )

                    // Color name
                    Text(colorName.capitalized)
                        .font(.body)

                    Spacer()

                    // Bead count
                    Text("\(count)")
                        .font(.headline)
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Pattern Color Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private var sortedColors: [(key: String, value: Int)] {
        patternViewModel.colors
            .sorted { $0.key < $1.key }
    }
}
