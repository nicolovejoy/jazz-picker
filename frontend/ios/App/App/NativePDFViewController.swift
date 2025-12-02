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
        setupUI()
        loadPDF()
        startHideTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide status bar completely
        setNeedsStatusBarAppearanceUpdate()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
        let targetSize = size ?? view.bounds.size
        let isLandscape = targetSize.width > targetSize.height

        if isLandscape {
            // Two pages side-by-side in landscape
            pdfView.displayMode = .twoUpContinuous
        } else {
            // Single page continuous allows horizontal swiping between pages
            pdfView.displayMode = .singlePageContinuous
        }
    }

    private func updateScale() {
        guard pdfView.document != nil else { return }
        // Scale up to fill screen (PDFs have margins we can crop into)
        let baseFactor = pdfView.scaleFactorForSizeToFit
        pdfView.scaleFactor = baseFactor * 1.05
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        // PDF View
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.backgroundColor = .white
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
        guard let url = URL(string: pdfURLString) else {
            showError("Invalid PDF URL")
            return
        }

        // Show loading indicator
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)

        // Capture crop bounds for async block
        let crop = self.cropBounds

        // Load PDF asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let document = PDFDocument(url: url) {
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

    private func toggleControls() {
        controlsVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = self.controlsVisible ? 1 : 0
            self.setlistBadge?.alpha = self.controlsVisible ? 1 : 0
        }
    }

    private func showControls() {
        guard !controlsVisible else { return }
        controlsVisible = true
        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = 1
            self.setlistBadge?.alpha = 1
        }
    }

    private func hideControls() {
        guard controlsVisible else { return }
        controlsVisible = false
        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = 0
            self.setlistBadge?.alpha = 0
        }
    }

    private func startHideTimer() {
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
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
