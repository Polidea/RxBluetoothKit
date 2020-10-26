import UIKit

class CentralServiceCell: UITableViewCell {

    static let reuseId: String = "service-cell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        uuidLabel.text = nil
        isPrimaryLabel.text = nil
        characterisicsCountLabel.text = nil
    }

    // MARK: - Subviews

    let uuidLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        return label
    }()

    let isPrimaryLabel: UILabel = {
        let label = UILabel()
        label.text = "isPrimary: --"
        return label
    }()

    let characterisicsCountLabel: UILabel = {
        let label = UILabel()
        label.text = "charac. count: --"
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
        [uuidLabel, isPrimaryLabel, characterisicsCountLabel].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0)
        ])
    }

}
