import UIKit

class CentralView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Subviews

    let serviceUuidTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Service UUID"
        return textField
    }()

    let characteristicUuidTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Characteristic UUID"
        return textField
    }()

    let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect", for: .normal)
        button.setImage(UIImage(systemName: "bolt.horizontal"), for: .normal)
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
        [serviceUuidTextField, characteristicUuidTextField, connectButton].forEach(stackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -32)
        ])
    }

}
