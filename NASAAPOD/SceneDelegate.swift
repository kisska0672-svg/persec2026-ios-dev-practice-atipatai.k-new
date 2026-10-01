import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        print("NASA APOD SceneDelegate willConnectTo")

        guard let windowScene = scene as? UIWindowScene else {
            print("NASA APOD failed to create window: scene is not UIWindowScene")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let window = UIWindow(windowScene: windowScene)

        let rootViewController = storyboard.instantiateInitialViewController()
        if let navigationController = rootViewController as? UINavigationController {
            navigationController.navigationBar.prefersLargeTitles = false
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.view.backgroundColor = .systemBackground

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
        }

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window
    }
}
