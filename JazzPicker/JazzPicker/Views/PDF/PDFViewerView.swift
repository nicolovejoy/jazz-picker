//
//  PDFViewerView.swift
//  JazzPicker
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @State var song: Song
    @State var concertKey: String
    let instrument: Instrument
    @State var navigationContext: PDFNavigationContext

    @Environment(\.dismiss) private var dismiss
    @Environment(CachedKeysStore.self) private var cachedKeysStore
    @Environment(SetlistStore.self) private var setlistStore

    @State private var pdfDocument: PDFDocument?
    @State private var cropBounds: CropBounds?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var isLandscape = false
    @State private var showKeyPicker = false
    @State private var showAddToSetlist = false

    // Page tracking for boundary detection
    @State private var isAtFirstPage = true
    @State private var isAtLastPage = true
    @State private var pageCount = 1

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
                    .gesture(horizontalSwipeGesture)
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
            }
            .contentShape(Rectangle()) // Make entire area tappable/swipeable
            .onTapGesture {
                withAnimation {
                    showControls.toggle()
                }
                if showControls {
                    scheduleHideControls()
                }
            }
            .highPriorityGesture(swipeDownGesture)
            .onChange(of: geometry.size) { _, newSize in
                isLandscape = newSize.width > newSize.height
            }
            .onAppear {
                isLandscape = geometry.size.width > geometry.size.height
                scheduleHideControls()
            }
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showKeyPicker = true
                    } label: {
                        Label("Change Key", systemImage: "music.quarternote.3")
                    }
                    Button {
                        showAddToSetlist = true
                    } label: {
                        Label("Add to Setlist", systemImage: "text.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(song.title)
                        .font(.headline)
                    Text(formatKeyForDisplay(concertKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbarVisibility(showControls || error != nil ? .visible : .hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!showControls && error == nil)
        .task(id: "\(song.id)-\(concertKey)") {
            await loadPDF()
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
        .sheet(isPresented: $showKeyPicker) {
            KeyPickerSheet(
                currentKey: concertKey,
                standardKey: song.defaultKey
            ) { newKey in
                changeKey(to: newKey)
            }
        }
        .sheet(isPresented: $showAddToSetlist) {
            AddToSetlistSheet(songTitle: song.title, concertKey: concertKey)
        }
    }

    // MARK: - Key Change

    private func changeKey(to newKey: String) {
        guard newKey != concertKey else { return }

        // Update sticky key in store
        cachedKeysStore.setStickyKey(newKey, for: song)

        // Update concert key (triggers PDF reload via task)
        concertKey = newKey
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

        return isMinor ? result + "m" : result
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

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = abs(value.translation.height)

                // Only handle horizontal swipes
                guard abs(horizontalDistance) > verticalDistance else { return }
                guard abs(horizontalDistance) > 100 else { return }

                if horizontalDistance < 0 {
                    // Swipe left → next
                    handleSwipeNext()
                } else {
                    // Swipe right → previous
                    handleSwipePrevious()
                }
            }
    }

    private func handleSwipeNext() {
        print("👆 handleSwipeNext - isAtLastPage: \(isAtLastPage), pageCount: \(pageCount)")
        // If not at last page of current PDF, let PDFKit handle it
        guard isAtLastPage else {
            print("👆 Not at last page, ignoring swipe")
            return
        }

        // At last page - try to go to next song
        if let next = navigationContext.nextSong() {
            print("👆 Navigating to next: \(next.song.title)")
            navigateToSong(next.song, concertKey: next.concertKey, context: next.newContext)
        } else {
            print("👆 No next song, haptic feedback")
            // Boundary - provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func handleSwipePrevious() {
        // If not at first page of current PDF, let PDFKit handle it
        guard isAtFirstPage else { return }

        // At first page - try to go to previous song
        if let prev = navigationContext.previousSong() {
            navigateToSong(prev.song, concertKey: prev.concertKey, context: prev.newContext)
        } else {
            // Boundary - provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func navigateToSong(_ newSong: Song, concertKey newKey: String, context newContext: PDFNavigationContext) {
        print("🔄 navigateToSong: \(newSong.title) (key: \(newKey))")
        print("🔄 Old song.id: \(song.id), New song.id: \(newSong.id)")
        withAnimation(.easeInOut(duration: 0.3)) {
            song = newSong
            concertKey = newKey
            navigationContext = newContext
            // Reset page tracking
            isAtFirstPage = true
            isAtLastPage = true
        }
        print("🔄 State updated, song is now: \(song.title)")
    }

    // MARK: - Page Tracking

    private func handlePageChange(currentPage: Int, totalPages: Int) {
        pageCount = totalPages
        isAtFirstPage = currentPage == 0
        // In 2-up mode, last page might be pageCount-1 or pageCount-2 depending on odd/even
        isAtLastPage = currentPage >= totalPages - (isLandscape ? 2 : 1)
    }

    // MARK: - Controls

    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled {
                withAnimation {
                    showControls = false
                }
            }
        }
    }

    private func cancelHideControls() {
        hideControlsTask?.cancel()
    }

    private func loadPDF() async {
        print("📄 Loading PDF for: \(song.title) in key: \(concertKey)")
        isLoading = true
        error = nil
        // Keep pdfDocument intact during load for smooth transition

        do {
            let response = try await APIClient.shared.generatePDF(
                song: song.title,
                concertKey: concertKey,
                transposition: instrument.transposition,
                clef: instrument.clef,
                instrumentLabel: instrument.label
            )
            print("📄 Got URL: \(response.url.prefix(80))...")

            guard let url = URL(string: response.url) else {
                print("❌ Invalid URL")
                throw PDFError.invalidURL
            }

            // Download PDF data
            let (data, httpResponse) = try await URLSession.shared.data(from: url)
            print("📄 Downloaded \(data.count) bytes")

            if let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("❌ HTTP error: \(httpResponse.statusCode)")
                throw PDFError.downloadFailed(statusCode: httpResponse.statusCode)
            }

            guard let document = PDFDocument(data: data) else {
                print("❌ PDFDocument init failed")
                throw PDFError.invalidPDF
            }

            self.pdfDocument = document
            self.cropBounds = response.crop
            self.error = nil
            print("✅ PDF loaded: \(document.pageCount) pages")

            // Initialize page tracking
            self.pageCount = document.pageCount
            self.isAtFirstPage = true
            self.isAtLastPage = document.pageCount <= (isLandscape ? 2 : 1)

        } catch is CancellationError {
            print("⚠️ PDF load cancelled for: \(song.title)")
            // Don't set error for cancellation - another load is in progress
        } catch {
            print("❌ PDF load failed: \(error)")
            self.error = error
            // Clear document on error so error view shows
            self.pdfDocument = nil
        }

        isLoading = false
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
            song: Song(title: "Blue Bossa", defaultKey: "c", lowNoteMidi: nil, highNoteMidi: nil),
            concertKey: "c",
            instrument: .trumpet,
            navigationContext: .single
        )
    }
    .environment(CachedKeysStore())
    .environment(SetlistStore())
}
