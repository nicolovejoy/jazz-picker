//
//  PDFViewerView.swift
//  JazzPicker
//

import SwiftUI
import PDFKit
import UIKit

struct PDFViewerView: View {
    @State var song: Song
    @State var concertKey: String
    let instrument: Instrument
    @State var navigationContext: PDFNavigationContext

    init(song: Song, concertKey: String, instrument: Instrument, octaveOffset: Int? = nil, navigationContext: PDFNavigationContext) {
        self._song = State(initialValue: song)
        self._concertKey = State(initialValue: concertKey)
        self.instrument = instrument
        self._navigationContext = State(initialValue: navigationContext)
        // Initialize octave offset: explicit param > setlist item > 0
        let initialOctave = octaveOffset ?? navigationContext.currentSetlistItem?.octaveOffset ?? 0
        self._octaveOffset = State(initialValue: initialOctave)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    @EnvironmentObject private var setlistStore: SetlistStore
    @EnvironmentObject private var pdfCacheService: PDFCacheService
    @EnvironmentObject private var grooveSyncStore: GrooveSyncStore
    @EnvironmentObject private var metronomeStore: MetronomeStore

    @State private var pdfDocument: PDFDocument?
    @State private var cropBounds: CropBounds?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showControls = false
    @State private var isLandscape = false
    @State private var showKeyPicker = false
    @State private var showAddToSetlist = false
    @State private var octaveOffset: Int
    @State private var pendingOctaveSave: Task<Void, Never>?

    // Page tracking for boundary detection
    @State private var isAtFirstPage = true
    @State private var isAtLastPage = true
    @State private var pageCount = 1

    // Auto-hide timer for controls
    @State private var hideControlsTask: Task<Void, Never>?
    private let autoHideDelay: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds

    /// Song range in MIDI notes (for ambitus display in key picker)
    private var songRange: (low: Int, high: Int)? {
        guard let low = song.lowNoteMidi, let high = song.highNoteMidi else { return nil }
        return (low, high)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Show previous PDF while loading next (prevents blank flash)
                if let document = pdfDocument {
                    PDFKitView(
                        document: document,
                        cropBounds: cropBounds,
                        isLandscape: isLandscape,
                        onPageChange: handlePageChange
                    )
                    .ignoresSafeArea()
                }

                // Loading overlay
                if isLoading {
                    ZStack {
                        if pdfDocument != nil {
                            // Translucent overlay when transitioning between songs
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                        }
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(pdfDocument != nil ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Error state
                if let error, !isLoading {
                    VStack(spacing: 20) {
                        ContentUnavailableView(
                            "Failed to Load PDF",
                            systemImage: "doc.questionmark",
                            description: Text(error.localizedDescription)
                        )
                        Button("Go Back") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // MARK: - Edge Navigation Zones
                HStack(spacing: 0) {
                    // Left edge - previous song
                    Color.clear
                        .frame(width: 70)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTapPrevious()
                        }

                    Spacer()

                    // Right edge - next song
                    Color.clear
                        .frame(width: 70)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTapNext()
                        }
                }

                // MARK: - Chevron Indicators
                if showControls {
                    HStack {
                        // Left chevron
                        if navigationContext.canGoPrevious {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.3))
                                .frame(width: 70)
                        } else {
                            Spacer().frame(width: 70)
                        }

                        Spacer()

                        // Right chevron
                        if navigationContext.canGoNext {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.3))
                                .frame(width: 70)
                        } else {
                            Spacer().frame(width: 70)
                        }
                    }
                    .allowsHitTesting(false) // Chevrons are visual only, tap zones handle input
                }

                // MARK: - Visual Beat Pulse
                BeatPulseOverlay()

                // MARK: - Metronome Overlay
                if metronomeStore.isVisible {
                    VStack {
                        HStack {
                            Spacer()
                            MetronomeOverlayView(onInteraction: resetAutoHideTimer)
                                .padding(.top, 60)
                                .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: metronomeStore.isVisible)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showControls.toggle()
                }
                if showControls {
                    startAutoHideTimer()
                    // Auto-show metronome if it's playing
                    if metronomeStore.engine.isPlaying {
                        metronomeStore.show()
                    }
                }
            }
            .highPriorityGesture(swipeDownGesture)
            .onChange(of: geometry.size) { _, newSize in
                isLandscape = newSize.width > newSize.height
            }
            .onAppear {
                isLandscape = geometry.size.width > geometry.size.height
            }
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    // Octave controls
                    Button {
                        octaveOffset += 1
                    } label: {
                        Label("Octave +", systemImage: "arrow.up")
                    }
                    .disabled(octaveOffset >= 2)

                    Button {
                        octaveOffset -= 1
                    } label: {
                        Label("Octave −", systemImage: "arrow.down")
                    }
                    .disabled(octaveOffset <= -2)

                    Divider()

                    Button {
                        showKeyPicker = true
                    } label: {
                        Label("Change Key", systemImage: "music.quarternote.3")
                    }

                    Button {
                        printPDF()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    .disabled(pdfDocument == nil)

                    Divider()

                    // Add to setlist options
                    if let current = setlistStore.currentSetlist {
                        Button {
                            addToCurrentSetlist(current)
                        } label: {
                            Label("Add to \(current.name)", systemImage: "text.badge.plus")
                        }
                        .disabled(setlistStore.containsSong(song.title, in: current))

                        Button {
                            showAddToSetlist = true
                        } label: {
                            Label("Add to Other Setlist...", systemImage: "text.badge.plus")
                        }
                    } else {
                        Button {
                            showAddToSetlist = true
                        } label: {
                            Label("Add to Setlist...", systemImage: "text.badge.plus")
                        }
                    }

                    Divider()

                    Button {
                        Task { @MainActor in
                            print("🎵 Metronome button tapped")
                            metronomeStore.loadFromSong(song)
                            print("🎵 After loadFromSong, about to call show()")
                            metronomeStore.show()
                            print("🎵 After show()")
                        }
                    } label: {
                        Label("Metronome", systemImage: "metronome")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 24))
                }
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(song.title)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(formatKeyForDisplay(concertKey))
                        if octaveOffset != 0 {
                            Text("(\(octaveOffset > 0 ? "+" : "")\(octaveOffset) oct)")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .toolbar(showControls || error != nil ? .visible : .hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!showControls && error == nil)
        .task(id: "\(song.id)-\(concertKey)-\(octaveOffset)") {
            await loadPDF()
        }
        .onAppear {
            // Prevent iPad from sleeping during gig
            UIApplication.shared.isIdleTimerDisabled = true

            // Apply user preference if not in setlist context and no octave set
            if navigationContext.currentSetlistItem == nil, octaveOffset == 0 {
                if let preferred = cachedKeysStore.getPreferredOctaveOffset(for: song) {
                    octaveOffset = preferred
                }
            }
        }
        .onDisappear {
            pendingOctaveSave?.cancel()
            hideControlsTask?.cancel()
            // Re-enable sleep when leaving PDF view
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: octaveOffset) { _, newOffset in
            Task { @MainActor in
                saveOctaveOffset(newOffset)
            }
        }
        .sheet(isPresented: $showKeyPicker) {
            KeyPickerSheet(
                currentKey: concertKey,
                standardKey: song.defaultKey,
                songRange: songRange
            ) { newKey in
                changeKey(to: newKey)
            }
        }
        .sheet(isPresented: $showAddToSetlist) {
            AddToSetlistSheet(songTitle: song.title, concertKey: concertKey, octaveOffset: octaveOffset)
        }
    }

    // MARK: - Auto-Hide Controls

    private func startAutoHideTimer() {
        // Cancel existing timer
        hideControlsTask?.cancel()

        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: autoHideDelay)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation {
                    showControls = false
                    metronomeStore.hide()
                }
            }
        }
    }

    private func resetAutoHideTimer() {
        if showControls {
            startAutoHideTimer()
        }
    }

    // MARK: - Groove Sync

    /// If we're leading a Groove Sync session, sync the current song to followers
    private func syncSongIfLeading() {
        print("🎵 syncSongIfLeading called - isLeading: \(grooveSyncStore.isLeading)")
        guard grooveSyncStore.isLeading else {
            print("🎵 Not leading, skipping sync")
            return
        }

        // Determine source based on catalog (standard vs custom)
        // For now, assume standard - we can enhance this later
        let source = "standard"

        print("🎵 Syncing song: \(song.title) in key \(concertKey) (octave: \(octaveOffset))")
        Task {
            await grooveSyncStore.syncSong(title: song.title, concertKey: concertKey, source: source, octaveOffset: octaveOffset)
        }
    }

    // MARK: - Octave Persistence

    private func saveOctaveOffset(_ offset: Int) {
        // Cancel any pending save
        pendingOctaveSave?.cancel()

        // Debounce: wait 500ms before saving to avoid rapid API calls
        pendingOctaveSave = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else {
                print("🎵 saveOctaveOffset: cancelled")
                return
            }

            // Priority: setlist item > user preference
            if let setlistID = navigationContext.setlistID,
               let item = navigationContext.currentSetlistItem {
                // Save to setlist item
                print("🎵 saveOctaveOffset: \(offset) for item \(item.id) in setlist \(setlistID)")
                guard let setlist = setlistStore.setlists.first(where: { $0.id == setlistID }) else {
                    print("🎵 saveOctaveOffset: setlist not found in store")
                    return
                }
                await setlistStore.updateItemOctaveOffset(in: setlist, itemID: item.id, octaveOffset: offset)
            } else {
                // Save to user preference
                print("🎵 saveOctaveOffset: \(offset) as preference for \(song.title)")
                cachedKeysStore.setPreferredOctaveOffset(offset, for: song)
            }
        }
    }

    // MARK: - Add to Setlist

    private func addToCurrentSetlist(_ setlist: Setlist) {
        Task {
            do {
                try await setlistStore.addSong(to: setlist, songTitle: song.title, concertKey: concertKey, octaveOffset: octaveOffset)
            } catch {
                print("❌ Failed to add to setlist: \(error)")
            }
        }
    }

    // MARK: - Key Change

    private func changeKey(to newKey: String) {
        guard newKey != concertKey else { return }

        // Update sticky key in store
        cachedKeysStore.setStickyKey(newKey, for: song)

        // Update concert key (triggers PDF reload via task)
        // Note: octave preference is per-song, not per-key, so we keep the current offset
        concertKey = newKey
    }

    // MARK: - Print

    private func printPDF() {
        guard let document = pdfDocument,
              let pdfData = document.dataRepresentation() else {
            return
        }

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "\(song.title) - \(formatKeyForDisplay(concertKey))"
        printInfo.outputType = .general

        printController.printInfo = printInfo
        printController.printingItem = pdfData

        printController.present(animated: true)
    }

    private func formatKeyForDisplay(_ key: String) -> String {
        let isMinor = key.hasSuffix("m")
        let pitchPart = isMinor ? String(key.dropLast()) : key

        var result = pitchPart.prefix(1).uppercased()

        if pitchPart.count > 1 {
            let modifier = pitchPart.dropFirst()
            if modifier == "f" {
                result += "b"
            } else if modifier == "s" {
                result += "#"
            }
        }

        return isMinor ? result + " Minor" : result
    }

    // MARK: - Gestures

    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let verticalDistance = value.translation.height
                let horizontalDistance = abs(value.translation.width)

                // Swipe down: vertical movement > horizontal and downward
                if verticalDistance > 100 && verticalDistance > horizontalDistance {
                    dismiss()
                }
            }
    }

    // MARK: - Edge Tap Navigation

    private func handleTapNext() {
        if let next = navigationContext.nextSong() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Use sticky key if set, otherwise use the context's key
            let key = cachedKeysStore.getStickyKey(for: next.song) ?? next.concertKey
            navigateToSong(next.song, concertKey: key, context: next.newContext)
        } else {
            // Boundary - provide warning haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func handleTapPrevious() {
        if let prev = navigationContext.previousSong() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Use sticky key if set, otherwise use the context's key
            let key = cachedKeysStore.getStickyKey(for: prev.song) ?? prev.concertKey
            navigateToSong(prev.song, concertKey: key, context: prev.newContext)
        } else {
            // Boundary - provide warning haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func navigateToSong(_ newSong: Song, concertKey newKey: String, context newContext: PDFNavigationContext) {
        print("🔄 navigateToSong: \(newSong.title) (key: \(newKey))")
        print("🔄 Old song.id: \(song.id), New song.id: \(newSong.id)")

        // Priority: setlist item > user preference > 0
        let newOctaveOffset: Int
        if let setlistOffset = newContext.currentSetlistItem?.octaveOffset {
            newOctaveOffset = setlistOffset
        } else if let preferredOffset = cachedKeysStore.getPreferredOctaveOffset(for: newSong) {
            newOctaveOffset = preferredOffset
        } else {
            newOctaveOffset = 0
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            song = newSong
            concertKey = newKey
            navigationContext = newContext
            octaveOffset = newOctaveOffset
            // Reset page tracking
            isAtFirstPage = true
            isAtLastPage = true
        }
        print("🔄 State updated, song is now: \(song.title)")
    }

    // MARK: - Page Tracking

    private func handlePageChange(currentPage: Int, totalPages: Int) {
        Task { @MainActor in
            pageCount = totalPages
            isAtFirstPage = currentPage == 0
            // In 2-up mode, last page might be pageCount-1 or pageCount-2 depending on odd/even
            isAtLastPage = currentPage >= totalPages - (isLandscape ? 2 : 1)
        }
    }

    private func loadPDF() async {
        print("📄 Loading PDF for: \(song.title) in key: \(concertKey)")
        isLoading = true
        error = nil
        // Keep pdfDocument intact during load for smooth transition

        // Check cache first
        let cacheResult = pdfCacheService.getCachedPDF(
            songTitle: song.title,
            concertKey: concertKey,
            transposition: instrument.transposition,
            clef: instrument.clef,
            octaveOffset: octaveOffset
        )

        // If cached, show immediately while we check for updates
        if case .hit(let cachedData, let cachedCrop) = cacheResult {
            if let document = PDFDocument(data: cachedData) {
                self.pdfDocument = document
                self.cropBounds = cachedCrop
                self.pageCount = document.pageCount
                self.isAtFirstPage = true
                self.isAtLastPage = document.pageCount <= (isLandscape ? 2 : 1)
                print("📦 Serving from cache: \(song.title)")
            }
        }

        do {
            // Get ETag for conditional request
            let existingETag = pdfCacheService.getETag(
                songTitle: song.title,
                concertKey: concertKey,
                transposition: instrument.transposition,
                clef: instrument.clef,
                octaveOffset: octaveOffset
            )

            let response = try await APIClient.shared.generatePDF(
                song: song.title,
                concertKey: concertKey,
                transposition: instrument.transposition,
                clef: instrument.clef,
                instrumentLabel: instrument.label,
                octaveOffset: octaveOffset == 0 ? nil : octaveOffset
            )

            // Update octaveOffset from auto-calculated value if we got one
            if let calculatedOctave = response.octaveOffset, octaveOffset == 0 {
                await MainActor.run {
                    self.octaveOffset = calculatedOctave
                }
            }
            print("📄 Got URL: \(response.url.prefix(80))...")

            guard let url = URL(string: response.url) else {
                print("❌ Invalid URL")
                throw PDFError.invalidURL
            }

            // Build request with conditional header if we have cached version
            var request = URLRequest(url: url)
            if let etag = existingETag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }

            // Download PDF data
            let (data, httpResponse) = try await URLSession.shared.data(for: request)

            if let httpResponse = httpResponse as? HTTPURLResponse {
                if httpResponse.statusCode == 304 {
                    // Not modified - cache is fresh
                    print("✅ Cache validated (304): \(song.title)")
                    pdfCacheService.updateETag(
                        songTitle: song.title,
                        concertKey: concertKey,
                        transposition: instrument.transposition,
                        clef: instrument.clef,
                        octaveOffset: octaveOffset,
                        etag: httpResponse.value(forHTTPHeaderField: "ETag")
                    )
                    // pdfDocument already set from cache above
                    isLoading = false
                    // Sync to followers if we're leading
                    syncSongIfLeading()
                    return
                } else if httpResponse.statusCode != 200 {
                    print("❌ HTTP error: \(httpResponse.statusCode)")
                    throw PDFError.downloadFailed(statusCode: httpResponse.statusCode)
                }

                // Got fresh data - cache it
                let newETag = httpResponse.value(forHTTPHeaderField: "ETag")
                print("📄 Downloaded \(data.count) bytes")

                guard let document = PDFDocument(data: data) else {
                    print("❌ PDFDocument init failed")
                    throw PDFError.invalidPDF
                }

                // Cache the PDF
                pdfCacheService.cachePDF(
                    data: data,
                    songTitle: song.title,
                    concertKey: concertKey,
                    transposition: instrument.transposition,
                    clef: instrument.clef,
                    octaveOffset: octaveOffset,
                    etag: newETag,
                    cropBounds: response.crop
                )

                self.pdfDocument = document
                self.cropBounds = response.crop
                self.error = nil
                print("✅ PDF loaded: \(document.pageCount) pages")

                // Initialize page tracking
                self.pageCount = document.pageCount
                self.isAtFirstPage = true
                self.isAtLastPage = document.pageCount <= (isLandscape ? 2 : 1)
            }

        } catch is CancellationError {
            print("⚠️ PDF load cancelled for: \(song.title)")
            // Don't set error for cancellation - another load is in progress
        } catch {
            print("❌ PDF load failed: \(error)")
            // If we have cached data, keep showing it
            if case .hit = cacheResult {
                print("📦 Offline - using cached version")
                self.error = nil
            } else {
                self.error = error
                // Clear document on error so error view shows
                self.pdfDocument = nil
            }
        }

        isLoading = false

        // If we successfully loaded and we're leading Groove Sync, sync this song
        if error == nil {
            syncSongIfLeading()
        }
    }
}

enum PDFError: Error, LocalizedError {
    case invalidURL
    case invalidPDF
    case downloadFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid PDF URL"
        case .invalidPDF: return "Could not load PDF document"
        case .downloadFailed(let code): return "Download failed (HTTP \(code))"
        }
    }
}

// MARK: - PDFKit UIViewRepresentable

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    let cropBounds: CropBounds?
    let isLandscape: Bool
    let onPageChange: (Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPageChange: onPageChange)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.backgroundColor = .white
        pdfView.pageShadowsEnabled = false
        pdfView.pageBreakMargins = .zero

        // Apply crop bounds if available
        if let crop = cropBounds {
            applyCropBounds(crop, to: document)
        }

        configureDisplayMode(pdfView)

        // Set up page change observation
        context.coordinator.setupPageChangeObserver(for: pdfView, document: document)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document

            if let crop = cropBounds {
                applyCropBounds(crop, to: document)
            }

            // Update coordinator with new document
            context.coordinator.setupPageChangeObserver(for: pdfView, document: document)
        }

        configureDisplayMode(pdfView)
    }

    private func configureDisplayMode(_ pdfView: PDFView) {
        if isLandscape {
            // 2-up side by side in landscape
            pdfView.displayMode = .twoUp
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(false)
        } else {
            // Single page with swipe in portrait
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .horizontal
            pdfView.usePageViewController(true)
        }
    }

    private func applyCropBounds(_ crop: CropBounds, to document: PDFDocument) {
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }

            let mediaBox = page.bounds(for: .mediaBox)

            let croppedRect = CGRect(
                x: mediaBox.origin.x + crop.left,
                y: mediaBox.origin.y + crop.bottom,
                width: mediaBox.width - crop.left - crop.right,
                height: mediaBox.height - crop.top - crop.bottom
            )

            page.setBounds(croppedRect, for: .cropBox)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        let onPageChange: (Int, Int) -> Void
        private var pageChangeObserver: NSObjectProtocol?
        private weak var currentDocument: PDFDocument?

        init(onPageChange: @escaping (Int, Int) -> Void) {
            self.onPageChange = onPageChange
        }

        func setupPageChangeObserver(for pdfView: PDFView, document: PDFDocument) {
            // Remove existing observer if document changed
            if let observer = pageChangeObserver {
                NotificationCenter.default.removeObserver(observer)
            }

            currentDocument = document

            // Report initial state
            reportCurrentPage(pdfView: pdfView, document: document)

            // Observe page changes
            pageChangeObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: pdfView,
                queue: .main
            ) { [weak self, weak pdfView, weak document] _ in
                guard let self, let pdfView, let document else { return }
                self.reportCurrentPage(pdfView: pdfView, document: document)
            }
        }

        private func reportCurrentPage(pdfView: PDFView, document: PDFDocument) {
            let totalPages = document.pageCount
            var currentPageIndex = 0

            if let currentPage = pdfView.currentPage {
                currentPageIndex = document.index(for: currentPage)
            }

            onPageChange(currentPageIndex, totalPages)
        }

        deinit {
            if let observer = pageChangeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PDFViewerView(
            song: Song(title: "Blue Bossa", defaultKey: "c", composer: nil, lowNoteMidi: nil, highNoteMidi: nil, scoreId: nil, partName: nil, tempoStyle: "Medium Bossa", tempoSource: "Kenny Dorham", tempoBpm: 140, tempoNoteValue: 4, timeSignature: "4/4"),
            concertKey: "c",
            instrument: .trumpet,
            navigationContext: .single
        )
    }
    .environmentObject(CachedKeysStore())
    .environmentObject(SetlistStore())
    .environmentObject(PDFCacheService.shared)
    .environmentObject(GrooveSyncStore())
    .environmentObject(MetronomeStore())
}
