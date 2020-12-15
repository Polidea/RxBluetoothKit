import UIKit

class CharacteristicReadView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Subviews

    let label: UILabel = {
        let label = UILabel()
        label.text = "Read value: --"
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.textColor = .green
        return label
    }()

    // MARK: - Private

    private func setupLayout() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
        ])
    }

}
