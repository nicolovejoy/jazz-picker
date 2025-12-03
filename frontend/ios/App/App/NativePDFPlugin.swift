import Foundation
import Capacitor
import PDFKit

struct CropBounds {
    let top: CGFloat
    let bottom: CGFloat
    let left: CGFloat
    let right: CGFloat
}

struct PDFItem {
    let localPath: String?
    let remoteUrl: String?
    let title: String
    let key: String
    let crop: CropBounds?
}

@objc(NativePDFPlugin)
public class NativePDFPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePDFPlugin"
    public let jsName = "NativePDF"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openSetlist", returnType: CAPPluginReturnPromise)
    ]

    @objc func open(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url") else {
            call.reject("URL is required")
            return
        }

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

        self.presentPDF(
            call: call,
            urlString: urlString,
            title: title,
            key: key,
            setlistIndex: setlistIndex,
            setlistTotal: setlistTotal,
            cropBounds: cropBounds,
            retryCount: 0
        )
    }

    private func presentPDF(
        call: CAPPluginCall,
        urlString: String,
        title: String,
        key: String,
        setlistIndex: Int?,
        setlistTotal: Int?,
        cropBounds: CropBounds?,
        retryCount: Int
    ) {
        DispatchQueue.main.async {
            guard let viewController = self.bridge?.viewController else {
                call.reject("No view controller available")
                return
            }

            // Ensure view is in window hierarchy before presenting
            guard viewController.view.window != nil else {
                // Retry up to 3 times with increasing delay
                if retryCount < 3 {
                    let delay = Double(retryCount + 1) * 0.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.presentPDF(
                            call: call,
                            urlString: urlString,
                            title: title,
                            key: key,
                            setlistIndex: setlistIndex,
                            setlistTotal: setlistTotal,
                            cropBounds: cropBounds,
                            retryCount: retryCount + 1
                        )
                    }
                    return
                }
                call.reject("View not in window hierarchy after retries")
                return
            }

            // If already presenting something, use the presented VC
            let presenterVC = viewController.presentedViewController ?? viewController

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

            presenterVC.present(pdfVC, animated: true)
        }
    }

    @objc func openSetlist(_ call: CAPPluginCall) {
        guard let itemsArray = call.getArray("items") as? [[String: Any]] else {
            call.reject("items array is required")
            return
        }

        let startIndex = call.getInt("startIndex") ?? 0

        // Parse items into PDFItem structs
        var pdfItems: [PDFItem] = []
        for itemDict in itemsArray {
            let localPath = itemDict["localPath"] as? String
            let remoteUrl = itemDict["remoteUrl"] as? String
            let title = itemDict["title"] as? String ?? "PDF"
            let key = itemDict["key"] as? String ?? ""

            var crop: CropBounds?
            if let cropDict = itemDict["crop"] as? [String: Any],
               let top = cropDict["top"] as? Double,
               let bottom = cropDict["bottom"] as? Double,
               let left = cropDict["left"] as? Double,
               let right = cropDict["right"] as? Double {
                crop = CropBounds(top: CGFloat(top), bottom: CGFloat(bottom), left: CGFloat(left), right: CGFloat(right))
            }

            pdfItems.append(PDFItem(localPath: localPath, remoteUrl: remoteUrl, title: title, key: key, crop: crop))
        }

        guard !pdfItems.isEmpty else {
            call.reject("No valid PDF items")
            return
        }

        presentSetlist(call: call, items: pdfItems, startIndex: startIndex, retryCount: 0)
    }

    private func presentSetlist(call: CAPPluginCall, items: [PDFItem], startIndex: Int, retryCount: Int) {
        DispatchQueue.main.async {
            guard let viewController = self.bridge?.viewController else {
                call.reject("No view controller available")
                return
            }

            guard viewController.view.window != nil else {
                if retryCount < 3 {
                    let delay = Double(retryCount + 1) * 0.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.presentSetlist(call: call, items: items, startIndex: startIndex, retryCount: retryCount + 1)
                    }
                    return
                }
                call.reject("View not in window hierarchy after retries")
                return
            }

            let presenterVC = viewController.presentedViewController ?? viewController

            let pdfVC = NativePDFViewController()
            pdfVC.pdfItems = items
            pdfVC.currentIndex = min(startIndex, items.count - 1)
            pdfVC.modalPresentationStyle = .fullScreen

            // Callback when user closes the viewer
            pdfVC.onClose = { [weak pdfVC] in
                call.resolve([
                    "action": "closed",
                    "finalIndex": pdfVC?.currentIndex ?? startIndex
                ])
            }

            presenterVC.present(pdfVC, animated: true)
        }
    }
}
