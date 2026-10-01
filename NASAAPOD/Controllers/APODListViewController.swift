import UIKit

@MainActor
final class APODListViewController: UIViewController {
    private enum SegueIdentifier {
        static let showDetail = "showDetail"
    }

    @IBOutlet private weak var monthButton: UIButton!
    @IBOutlet private weak var yearButton: UIButton!
    @IBOutlet private weak var searchButton: UIButton!
    @IBOutlet private weak var dateRangeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var filterStackView: UIStackView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let service: APODServing = APODService()
    private var items: [APODItem] = []

    private let calendar = Calendar(identifier: .gregorian)
    private let months = Array(1...12)
    private lazy var years: [Int] = {
        let currentYear = calendar.component(.year, from: Date())
        return Array(1995...currentYear).reversed()
    }()

    private var selectedMonth = Calendar(identifier: .gregorian).component(.month, from: Date())
    private var selectedYear = Calendar(identifier: .gregorian).component(.year, from: Date())

    override func viewDidLoad() {
        super.viewDidLoad()
        print("NASA APOD APODListViewController viewDidLoad")
        title = "NASA APOD"
        navigationItem.largeTitleDisplayMode = .never
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        additionalSafeAreaInsets = .zero
        view.backgroundColor = .systemBackground
        configureEdgeToEdgeLayout()
        configureControls()
        configureTableView()
        configureStatusViews()
        showInitialPrompt()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.setNeedsLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        tableView.contentInset.bottom = view.safeAreaInsets.bottom
        tableView.verticalScrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showDetail,
              let detailViewController = segue.destination as? APODDetailViewController,
              let item = sender as? APODItem else {
            return
        }

        detailViewController.item = item
    }

    private func configureControls() {
        monthButton.showsMenuAsPrimaryAction = true
        monthButton.changesSelectionAsPrimaryAction = false
        monthButton.configuration = .bordered()

        yearButton.showsMenuAsPrimaryAction = true
        yearButton.changesSelectionAsPrimaryAction = false
        yearButton.configuration = .bordered()

        searchButton.configuration = .filled()
        searchButton.setTitle("Search", for: .normal)
        configureButtonSizes()
        searchButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task {
                await self.loadSelectedMonth()
            }
        }, for: .touchUpInside)

        updateMenus()
    }

    private func configureButtonSizes() {
        [monthButton, yearButton, searchButton].forEach { button in
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }

    private func configureEdgeToEdgeLayout() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            constraint.firstItem === titleLabel
            || constraint.secondItem === titleLabel
            || constraint.firstItem === filterStackView
            || constraint.secondItem === filterStackView
            || constraint.firstItem === tableView
            || constraint.secondItem === tableView
            || constraint.identifier == "list-filter-top"
            || constraint.identifier == "list-table-top"
            || constraint.identifier == "list-table-bottom"
            || constraint.identifier == "list-table-leading"
            || constraint.identifier == "list-table-trailing"
            || constraint.identifier == "list-title-top"
            || constraint.identifier == "list-title-center-x"
        })

        tableView.contentInsetAdjustmentBehavior = .never

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            filterStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            filterStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            filterStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            filterStackView.heightAnchor.constraint(equalToConstant: 160),

            tableView.topAnchor.constraint(equalTo: filterStackView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112
        tableView.register(APODTableViewCell.self, forCellReuseIdentifier: APODTableViewCell.reuseIdentifier)
    }

    private func configureStatusViews() {
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.isHidden = true

        activityIndicator.hidesWhenStopped = true
        dateRangeLabel.textColor = .secondaryLabel
        dateRangeLabel.font = .preferredFont(forTextStyle: .caption1)
        dateRangeLabel.textAlignment = .center
        dateRangeLabel.numberOfLines = 1
        updateDateRangeLabel()
    }

    private func showInitialPrompt() {
        tableView.isHidden = true
        statusLabel.text = "Select a month and year, then tap Search."
        statusLabel.isHidden = false
    }

    private func updateMenus() {
        monthButton.setTitle(monthName(for: selectedMonth), for: .normal)
        yearButton.setTitle(String(selectedYear), for: .normal)

        monthButton.menu = UIMenu(children: months.map { month in
            UIAction(title: monthName(for: month), state: selectedMonth == month ? .on : .off) { [weak self] _ in
                self?.selectedMonth = month
                self?.updateMenus()
            }
        })

        yearButton.menu = UIMenu(children: years.map { year in
            UIAction(title: String(year), state: selectedYear == year ? .on : .off) { [weak self] _ in
                self?.selectedYear = year
                self?.updateMenus()
            }
        })

        updateDateRangeLabel()
    }

    private func updateDateRangeLabel() {
        guard let range = try? Date.monthRange(year: selectedYear, month: selectedMonth) else {
            dateRangeLabel.text = nil
            return
        }

        let endDate = min(range.end, Date())
        dateRangeLabel.text = "ข้อมูลจากวันที่ \(Self.displayDateFormatter.string(from: range.start)) - \(Self.displayDateFormatter.string(from: endDate))"
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func loadSelectedMonth() async {
        print("NASA APOD loadSelectedMonth year=\(selectedYear) month=\(selectedMonth)")
        setLoading(true)

        do {
            let range = try Date.monthRange(year: selectedYear, month: selectedMonth)
            let today = Date()

            guard range.start <= today else {
                items = []
                tableView.reloadData()
                statusLabel.text = "Selected month is in the future. Please choose a past month."
                statusLabel.isHidden = false
                setLoading(false)
                return
            }

            let endDate = min(range.end, today)
            print("NASA APOD calling service start=\(range.start) end=\(endDate)")
            items = try await service.fetchItems(startDate: range.start, endDate: endDate)
            print("NASA APOD received \(items.count) item(s)")
            tableView.reloadData()
            statusLabel.text = items.isEmpty ? "No APOD items. Try another month or year." : nil
            statusLabel.isHidden = items.isEmpty == false
        } catch {
            items = []
            tableView.reloadData()
            print("NASA APOD failed: \(error.localizedDescription)")
            statusLabel.text = error.localizedDescription
            statusLabel.isHidden = false
            showErrorAlert(message: error.localizedDescription)
        }

        setLoading(false)
    }

    private func showErrorAlert(message: String) {
        guard presentedViewController == nil else { return }

        let alertController = UIAlertController(
            title: "Unable to Load NASA APOD",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            tableView.isHidden = true
            statusLabel.isHidden = true
            activityIndicator.startAnimating()
        } else {
            tableView.isHidden = items.isEmpty
            activityIndicator.stopAnimating()
        }
    }

    private func monthName(for month: Int) -> String {
        DateFormatter().monthSymbols[month - 1]
    }
}

extension APODListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: APODTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? APODTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(with: items[indexPath.row])
        return cell
    }
}

extension APODListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("NASA APOD selected item date=\(items[indexPath.row].date), title=\(items[indexPath.row].title)")
        performSegue(withIdentifier: SegueIdentifier.showDetail, sender: items[indexPath.row])
    }
}
