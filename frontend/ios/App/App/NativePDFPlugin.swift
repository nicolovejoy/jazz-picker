import Foundation
import Capacitor
import PDFKit

struct CropBounds {
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat
    let right: CGFloat
}

@objc(NativePDFPlugin)
public class NativePDFPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePDFPlugin"
    public let jsName = "NativePDF"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise)
    ]

    private var lastOpenTime: Date?
    private let debounceInterval: TimeInterval = 0.3  // 300ms debounce

    @objc func open(_ call: CAPPluginCall) {
        print("[NativePDF Plugin] open() called")

        // Debounce rapid calls
        let now = Date()
        if let lastTime = lastOpenTime, now.timeIntervalSince(lastTime) < debounceInterval {
            print("[NativePDF Plugin] Debounced - too soon after last open")
            call.resolve(["action": "debounced"])
            return
        }
        lastOpenTime = now

        guard let urlString = call.getString("url") else {
            print("[NativePDF Plugin] ERROR: No URL provided")
            call.reject("URL is required")
            return
        }

        print("[NativePDF Plugin] URL received: \(urlString.prefix(100))...")

        let title = call.getString("title") ?? "PDF"
        let key = call.getString("key") ?? ""

        // Setlist navigation info
        let setlistIndex = call.getInt("setlistIndex")
        let setlistTotal = call.getInt("setlistTotal")

        // Crop bounds (trim amounts from each edge in points)
        var cropBounds: CropBounds?
        if let cropDict = call.getObject("crop") {
            if let top = cropDict["top"] as? Double,
               let bottom = cropDict["bottom"] as? Double,
               let left = cropDict["left"] as? Double,
               let right = cropDict["right"] as? Double {
                cropBounds = CropBounds(top: CGFloat(top), bottom: CGFloat(bottom), left: CGFloat(left), right: CGFloat(right))
            }
        }

        DispatchQueue.main.async {
            guard let viewController = self.bridge?.viewController else {
                print("[NativePDF Plugin] ERROR: No view controller available")
                call.reject("No view controller available")
                return
            }

            // Check if view is in window hierarchy
            guard viewController.view.window != nil else {
                print("[NativePDF Plugin] ERROR: View not in window hierarchy, retrying...")
                // Retry after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.open(call)
                }
                return
            }

            // Check if already presenting something
            if viewController.presentedViewController != nil {
                print("[NativePDF Plugin] Already presenting a view controller, dismissing first...")
                viewController.dismiss(animated: false) {
                    self.open(call)
                }
                return
            }

            print("[NativePDF Plugin] Presenting NativePDFViewController...")

            let pdfVC = NativePDFViewController()
            pdfVC.pdfURLString = urlString
            pdfVC.songTitle = title
            pdfVC.songKey = key
            pdfVC.setlistIndex = setlistIndex
            pdfVC.setlistTotal = setlistTotal
            pdfVC.cropBounds = cropBounds
            pdfVC.modalPresentationStyle = .fullScreen

            // Callback when user closes the viewer
            pdfVC.onClose = {
                call.resolve(["action": "closed"])
            }

            // Callbacks for setlist navigation
            pdfVC.onNextSong = {
                self.notifyListeners("nextSong", data: [:])
            }
            pdfVC.onPrevSong = {
                self.notifyListeners("prevSong", data: [:])
            }

            viewController.present(pdfVC, animated: true) {
                print("[NativePDF Plugin] Presentation complete")
            }
        }
    }
}
