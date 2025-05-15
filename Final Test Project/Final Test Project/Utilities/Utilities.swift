import UIKit

class Utilities {

    static let shared = Utilities()

    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            guard let topVC = self.topViewController() else {
                print("⚠️ Could not find top view controller.")
                return
            }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default){ _ in
                completion?()
            })
            topVC.present(alert, animated: true)
        }
    }

    private func topViewController(controller: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = controller as? UINavigationController {
            return topViewController(controller: nav.visibleViewController)
        }

        if let tab = controller as? UITabBarController {
            return topViewController(controller: tab.selectedViewController)
        }

        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }

        return controller
    }
}
