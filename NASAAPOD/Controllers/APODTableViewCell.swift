import UIKit

final class APODTableViewCell: UITableViewCell {
    static let reuseIdentifier = "APODTableViewCell"

    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private var imageTask: Task<Void, Never>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        configureLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        accessoryType = .disclosureIndicator
        configureLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        thumbnailImageView.image = UIImage(systemName: "photo")
    }

    func configure(with item: APODItem) {
        titleLabel.text = item.title
        dateLabel.text = item.date
        thumbnailImageView.image = UIImage(systemName: item.mediaType == "image" ? "photo" : "play.rectangle")

        let imageURL = item.mediaType == "image" ? (item.hdurl ?? item.url) : item.thumbnailUrl
        guard let imageURL else { return }

        imageTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    self?.thumbnailImageView.image = UIImage(data: data)
                }
            } catch {
                await MainActor.run {
                    self?.thumbnailImageView.image = UIImage(systemName: "photo")
                }
            }
        }
    }

    private func configureLayout() {
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = .secondarySystemBackground
        thumbnailImageView.tintColor = .secondaryLabel

        titleLabel.numberOfLines = 2
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        dateLabel.font = .preferredFont(forTextStyle: .subheadline)
        dateLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 88),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 88),

            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}
