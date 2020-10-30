import UIKit

class PeripheralView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Subviews

    let updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Update", for: .normal)
        button.setImage(UIImage(systemName: "sun.min"), for: .normal)
        return button
    }()

    let readButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Read", for: .normal)
        button.setImage(UIImage(systemName: "phone.fill.arrow.up.right"), for: .normal)
        return button
    }()

    let writeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Write", for: .normal)
        button.setImage(UIImage(systemName: "phone.fill.arrow.down.left"), for: .normal)
        return button
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20.0
        return stackView
    }()

    // MARK: - Private

    private func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        [updateButton, readButton, writeButton].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
        ])
    }

}
