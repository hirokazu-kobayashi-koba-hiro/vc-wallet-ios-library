import UIKit

extension UIApplication {
    
    public func topViewController() -> UIViewController? {
        
        guard let windowScene = self.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        return getTopViewController(from: keyWindow.rootViewController)
    }
    
    private func getTopViewController(from viewController: UIViewController?) -> UIViewController? {
        
        if let presentedViewController = viewController?.presentedViewController {
            return getTopViewController(from: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return getTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return getTopViewController(from: selectedViewController)
        }
        
        return viewController
    }
}
