import UIKit

class CentralListCell: UITableViewCell {

    static let reuseId = "CentralListCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = nil
        rssiLabel.text = nil
        identifierLabel.text = nil
    }

    // MARK: - Subviews

    let identifierLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        return label
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "name: --"
        return label
    }()

    let rssiLabel: UILabel = {
        let label = UILabel()
        label.text = "rssi: --"
        return label
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10.0
        return stackView
    }()

    // MARK: - Private

    private func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        [identifierLabel, nameLabel, rssiLabel].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0)
        ])
    }

}
