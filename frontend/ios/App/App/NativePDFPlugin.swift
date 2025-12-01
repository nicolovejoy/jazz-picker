import Foundation
import Capacitor
import PDFKit

@objc(NativePDFPlugin)
public class NativePDFPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePDFPlugin"
    public let jsName = "NativePDF"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise)
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

        DispatchQueue.main.async {
            guard let viewController = self.bridge?.viewController else {
                call.reject("No view controller available")
                return
            }

            let pdfVC = NativePDFViewController()
            pdfVC.pdfURLString = urlString
            pdfVC.songTitle = title
            pdfVC.songKey = key
            pdfVC.setlistIndex = setlistIndex
            pdfVC.setlistTotal = setlistTotal
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

            viewController.present(pdfVC, animated: true)
        }
    }
}
