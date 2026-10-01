import UIKit

final class LauncherViewController: UIViewController {
    private enum SegueIdentifier {
        static let showAPODList = "showAPODList"
    }

    private var didRedirect = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print("NASA APOD LauncherViewController viewDidLoad")
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        additionalSafeAreaInsets = .zero
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        redirectToAPODListIfNeeded()
    }

    private func redirectToAPODListIfNeeded() {
        guard didRedirect == false else { return }

        didRedirect = true
        print("NASA APOD launcher auto redirect")
        performSegue(withIdentifier: SegueIdentifier.showAPODList, sender: nil)
    }
}
