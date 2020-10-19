import UIKit

class WelcomeView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Subviews

    let centralButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("CENTRAL", for: .normal)
        button.setImage(UIImage(systemName: "antenna.radiowaves.left.and.right"), for: .normal)
        return button
    }()

    let peripheralButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PERIPHERAL", for: .normal)
        button.setImage(UIImage(systemName: "personalhotspot"), for: .normal)
        return button
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 30.0
        return stackView
    }()

    // MARK: - Private

    private func setupLayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [centralButton, peripheralButton].forEach(stackView.addArrangedSubview)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

}
