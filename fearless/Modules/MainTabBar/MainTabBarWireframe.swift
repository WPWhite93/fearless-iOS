import Foundation
import CommonWallet

final class MainTabBarWireframe: MainTabBarWireframeProtocol {
    func showNewWalletView(on view: MainTabBarViewProtocol?) {
        if let view = view {
            MainTabBarViewFactory.reloadWalletView(on: view, wireframe: self)
        }
    }

    func showNewCrowdloan(on view: MainTabBarViewProtocol?) -> UIViewController? {
        if let view = view {
            return MainTabBarViewFactory.reloadCrowdloanView(
                on: view
            )
        }

        return nil
    }

    func presentAccountImport(on view: MainTabBarViewProtocol?) {
        guard let tabBarController = view?.controller else {
            return
        }

        guard canPresentImport(on: tabBarController) else {
            return
        }

        guard let importController = AccountImportViewFactory
            .createViewForAdding()?.controller
        else {
            return
        }

        let navigationController = FearlessNavigationController(rootViewController: importController)

        let presentingController = tabBarController.topModalViewController
        presentingController.present(navigationController, animated: true, completion: nil)
    }

    // MARK: Private

    private func canPresentImport(on view: UIViewController) -> Bool {
        if isAuthorizing || isAlreadyImporting(on: view) {
            return false
        }

        return true
    }

    private func isAlreadyImporting(on view: UIViewController) -> Bool {
        let topViewController = view.topModalViewController
        let topNavigationController: UINavigationController?

        if let navigationController = topViewController as? UINavigationController {
            topNavigationController = navigationController
        } else if let tabBarController = topViewController as? UITabBarController {
            topNavigationController = tabBarController.selectedViewController as? UINavigationController
        } else {
            topNavigationController = nil
        }

        return topNavigationController?.viewControllers.contains {
            if ($0 as? OnboardingMainViewProtocol) != nil || ($0 as? AccountImportViewProtocol) != nil {
                return true
            } else {
                return false
            }
        } ?? false
    }

    func presentAppUpdateAlert(from view: ControllerBackedProtocol?) {
        let alert = UIAlertController(title: "Please update app", message: "This version is unsupported", preferredStyle: .alert)
        let updateAction = UIAlertAction(title: "Go appstore", style: .default) { _ in
            if let url = URL(string: "itms-apps://apple.com/app/id1537251089") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alert.addAction(updateAction)

        view?.controller.present(alert, animated: true, completion: nil)
    }
}
