import UIKit

class CentralView: UIView {

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        setupLayout()
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - Subviews

    let specificButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Specific", for: .normal)
        button.setImage(UIImage(systemName: "link.icloud"), for: .normal)
        return button
    }()

    let listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("List", for: .normal)
        button.setImage(UIImage(systemName: "list.bullet.indent"), for: .normal)
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
        [specificButton, listButton].forEach(stackView.addArrangedSubview)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

}
