import UIKit

final class APODDetailViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private weak var imageView: UIImageView!

    private let backButton = UIButton(type: .system)
    private let headerTitleLabel = UILabel()

    var item: APODItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        additionalSafeAreaInsets = .zero
        view.backgroundColor = .systemBackground
        configureHeader()
        configureEdgeToEdgeLayout()

        guard let item else {
            print("NASA APOD detail missing item")
            title = "Detail"
            showMissingItemMessage()
            return
        }

        print("NASA APOD detail item date=\(item.date), title=\(item.title)")
        title = item.date
        configureContent()
        loadImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        view.setNeedsLayout()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }

        return (navigationController?.viewControllers.count ?? 0) > 1
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        scrollView.contentInset.bottom = view.safeAreaInsets.bottom
        scrollView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    private func configureContent() {
        guard let item else { return }

        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentOffset = .zero

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.tintColor = .secondaryLabel
        imageView.image = UIImage(systemName: "photo")

        addLabel(item.title, font: .preferredFont(forTextStyle: .title1), color: .label)
        addMetadata(title: "Date", value: item.date)
        addMetadata(title: "Media Type", value: item.mediaType.capitalized)
        addMetadata(title: "Service Version", value: item.serviceVersion)

        if let copyright = item.copyright {
            addMetadata(title: "Copyright", value: copyright)
        }

        addLabel(item.explanation, font: .preferredFont(forTextStyle: .body), color: .label)

        if let url = item.url {
            addLinkButton(title: "Open APOD page", url: url)
        }

        if let hdurl = item.hdurl {
            addLinkButton(title: "Open HD image", url: hdurl)
        }
    }

    private func addMetadata(title: String, value: String) {
        addLabel("\(title): \(value)", font: .preferredFont(forTextStyle: .subheadline), color: .secondaryLabel)
    }

    private func addLabel(_ text: String, font: UIFont, color: UIColor) {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = font
        label.textColor = color
        label.text = text
        contentStack.addArrangedSubview(label)
    }

    private func addLinkButton(title: String, url: URL) {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        button.setTitle(title, for: .normal)
        button.addAction(UIAction { _ in
            UIApplication.shared.open(url)
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(button)
    }

    private func loadImage() {
        guard let item else { return }

        let imageURL = item.thumbnailUrl ?? item.hdurl ?? item.url?.imageFileURL

        guard let imageURL else {
            imageView.image = UIImage(systemName: item.mediaType == "image" ? "photo" : "play.rectangle")
            return
        }

        print("NASA APOD detail image request: \(imageURL.absoluteString)")

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                imageView.image = UIImage(data: data) ?? UIImage(systemName: "photo")
            } catch {
                print("NASA APOD detail image failed: \(error.localizedDescription)")
                imageView.image = UIImage(systemName: "photo")
            }
        }
    }

    private func showMissingItemMessage() {
        imageView.isHidden = true

        addLabel(
            "No APOD detail data was sent to this screen.",
            font: .preferredFont(forTextStyle: .body),
            color: .secondaryLabel
        )
    }

    private func configureHeader() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.backgroundColor = .secondarySystemBackground
        backButton.layer.cornerRadius = 22
        backButton.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerTitleLabel.font = .preferredFont(forTextStyle: .headline)
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.textColor = .label
        headerTitleLabel.text = item?.date ?? "Detail"

        view.addSubview(backButton)
        view.addSubview(headerTitleLabel)
    }

    private func configureEdgeToEdgeLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            constraint.firstItem === scrollView
            || constraint.secondItem === scrollView
            || constraint.identifier == "detail-scroll-top"
            || constraint.identifier == "detail-scroll-bottom"
            || constraint.identifier == "detail-scroll-leading"
            || constraint.identifier == "detail-scroll-trailing"
        })

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            headerTitleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            headerTitleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 10),
            headerTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -72),

            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

private extension URL {
    var imageFileURL: URL? {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        return imageExtensions.contains(pathExtension.lowercased()) ? self : nil
    }
}
