import UIKit

class CharacteristicCell: UITableViewCell {

    static let reuseId = "CharacteristicCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    override func prepareForReuse() {
        identifierLabel.text = nil
        readButton.tag = 0
        updateButton.tag = 0
        writeButton.tag = 0
    }

    // MARK: - Layout

    let identifierLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        return label
    }()

    let readButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Read", for: .normal)
        return button
    }()

    let updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Update", for: .normal)
        return button
    }()

    let writeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Write", for: .normal)
        return button
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4.0
        return stackView
    }()

    // MARK: - Private

    private func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        [identifierLabel, readButton, updateButton, writeButton].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0)
        ])
    }

}
