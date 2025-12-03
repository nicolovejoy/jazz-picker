import UIKit
import PDFKit

class NativePDFViewController: UIViewController {

    // MARK: - Properties
    var pdfURLString: String = ""
    var songTitle: String = ""
    var songKey: String = ""
    var setlistIndex: Int?
    var setlistTotal: Int?
    var cropBounds: CropBounds?

    var onClose: (() -> Void)?
    var onNextSong: (() -> Void)?
    var onPrevSong: (() -> Void)?

    private var pdfView: PDFView!
    private var closeButton: UIButton!
    private var setlistBadge: UILabel?
    private var controlsVisible = true
    private var hideTimer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Extend content under status bar and home indicator
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true

        // Capture status bar appearance from this VC when presented modally
        modalPresentationCapturesStatusBarAppearance = true

        setupUI()
        loadPDF()
        startHideTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateDisplayMode(for: size)
            self.updateScale()
        })
    }

    // MARK: - Display Mode

    private func updateDisplayMode(for size: CGSize? = nil) {
        // Always use single page - cleanest for full bleed
        // User swipes horizontally to change pages
        pdfView.displayMode = .singlePage

        // Update scale after mode change
        DispatchQueue.main.async {
            self.updateScale()
        }
    }

    private func updateScale() {
        guard let document = pdfView.document,
              let page = document.page(at: 0) else { return }

        // Calculate scale to fill width completely
        let pageRect = page.bounds(for: .cropBox)
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height

        // Scale to fit width (full bleed horizontally)
        let widthScale = viewWidth / pageRect.width
        // Scale to fit height
        let heightScale = viewHeight / pageRect.height

        // Use the larger scale to fill the view (may crop slightly)
        // Or use min to fit entirely - adjust based on preference
        let targetScale = min(widthScale, heightScale)

        pdfView.scaleFactor = targetScale
        pdfView.minScaleFactor = targetScale * 0.5
        pdfView.maxScaleFactor = targetScale * 4.0
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        // PDF View - configured for full bleed display
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.backgroundColor = .white
        pdfView.autoScales = false  // We'll control scaling manually
        pdfView.displayDirection = .horizontal
        pdfView.pageBreakMargins = UIEdgeInsets.zero
        pdfView.displaysPageBreaks = false

        // Remove shadows and extra chrome
        if #available(iOS 12.0, *) {
            pdfView.pageShadowsEnabled = false
        }

        // Remove internal scroll view insets
        if let scrollView = pdfView.subviews.first as? UIScrollView {
            scrollView.contentInset = .zero
            scrollView.scrollIndicatorInsets = .zero
        }

        view.addSubview(pdfView)

        // Set display mode based on current orientation
        updateDisplayMode()

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Close Button (top right)
        closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.systemBlue
        closeButton.layer.cornerRadius = 22
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Setlist Badge (bottom right) - only if in setlist
        if let index = setlistIndex, let total = setlistTotal {
            let badge = UILabel()
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.text = "\(index + 1) / \(total)"
            badge.textColor = .white
            badge.font = .systemFont(ofSize: 14, weight: .medium)
            badge.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            badge.layer.cornerRadius = 12
            badge.layer.masksToBounds = true
            badge.textAlignment = .center
            badge.layer.borderWidth = 1
            badge.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor

            // Add padding
            badge.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

            view.addSubview(badge)

            NSLayoutConstraint.activate([
                badge.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                badge.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
                badge.heightAnchor.constraint(equalToConstant: 32)
            ])

            setlistBadge = badge
        }

        // Tap gesture for showing/hiding controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)

        // Swipe down to close
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(closeTapped))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)

        // Swipe gestures for setlist navigation
        if setlistIndex != nil {
            let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            leftSwipe.direction = .left
            view.addGestureRecognizer(leftSwipe)

            let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            rightSwipe.direction = .right
            view.addGestureRecognizer(rightSwipe)
        }
    }

    private func loadPDF() {
        print("[NativePDF] loadPDF called with URL: \(pdfURLString)")

        guard let url = URL(string: pdfURLString) else {
            print("[NativePDF] ERROR: Invalid URL string")
            showError("Invalid PDF URL")
            return
        }

        print("[NativePDF] URL parsed successfully: \(url)")

        // Show loading indicator
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)

        // Capture crop bounds for async block
        let crop = self.cropBounds

        // Load PDF asynchronously
        print("[NativePDF] Starting async PDF load...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("[NativePDF] In background thread, attempting PDFDocument(url:)")
            if let document = PDFDocument(url: url) {
                print("[NativePDF] SUCCESS: Document loaded, pageCount=\(document.pageCount)")
                // Apply crop bounds to each page if specified
                if let crop = crop {
                    for i in 0..<document.pageCount {
                        if let page = document.page(at: i) {
                            let mediaBox = page.bounds(for: .mediaBox)
                            // Crop values are trim amounts from each edge
                            // PDF coordinates have origin at bottom-left
                            let croppedRect = CGRect(
                                x: mediaBox.origin.x + crop.left,
                                y: mediaBox.origin.y + crop.bottom,  // bottom in PDF = bottom trim
                                width: mediaBox.width - crop.left - crop.right,
                                height: mediaBox.height - crop.top - crop.bottom
                            )
                            page.setBounds(croppedRect, for: .cropBox)
                        }
                    }
                }

                DispatchQueue.main.async {
                    spinner.removeFromSuperview()
                    self?.pdfView.document = document
                    self?.updateScale()
                }
            } else {
                print("[NativePDF] FAILED: PDFDocument(url:) returned nil for \(url)")
                DispatchQueue.main.async {
                    spinner.removeFromSuperview()
                    self?.showError("Failed to load PDF")
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        toggleControls()
        resetHideTimer()
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let document = pdfView.document,
              let currentPage = pdfView.currentPage else {
            return
        }

        let pageIndex = document.index(for: currentPage)
        let isFirstPage = pageIndex == 0
        let isLastPage = pageIndex == document.pageCount - 1

        if gesture.direction == .right && isFirstPage {
            // Swipe right on first page -> previous song
            dismiss(animated: true) { [weak self] in
                self?.onPrevSong?()
            }
        } else if gesture.direction == .left && isLastPage {
            // Swipe left on last page -> next song
            dismiss(animated: true) { [weak self] in
                self?.onNextSong?()
            }
        }
    }

    // MARK: - Controls Visibility

    private let controlsAnimationDuration: TimeInterval = 0.3
    private let controlsAutoHideDelay: TimeInterval = 1.5

    private var allControls: [UIView] {
        [closeButton, setlistBadge].compactMap { $0 }
    }

    private func setControlsAlpha(_ alpha: CGFloat) {
        UIView.animate(withDuration: controlsAnimationDuration) {
            self.allControls.forEach { $0.alpha = alpha }
        }
    }

    private func toggleControls() {
        controlsVisible.toggle()
        setControlsAlpha(controlsVisible ? 1 : 0)
    }

    private func showControls() {
        guard !controlsVisible else { return }
        controlsVisible = true
        setControlsAlpha(1)
    }

    private func hideControls() {
        guard controlsVisible else { return }
        controlsVisible = false
        setControlsAlpha(0)
    }

    private func startHideTimer() {
        hideTimer = Timer.scheduledTimer(withTimeInterval: controlsAutoHideDelay, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    private func resetHideTimer() {
        hideTimer?.invalidate()
        showControls()
        startHideTimer()
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.closeTapped()
        })
        present(alert, animated: true)
    }
}
