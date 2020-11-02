import UIKit

class PeripheralViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var peripheralView = PeripheralView()

    override func loadView() {
        view = peripheralView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralView.updateButton.addTarget(self, action: #selector(handleUpdateButton), for: .touchUpInside)
        peripheralView.readButton.addTarget(self, action: #selector(handleReadButton), for: .touchUpInside)
        peripheralView.writeButton.addTarget(self, action: #selector(handleWriteButton), for: .touchUpInside)
    }

    // MARK: - Private

    @objc private func handleUpdateButton() {
        let controller = PeripheralUpdateViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func handleReadButton() {
        let controller = PeripheralReadViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func handleWriteButton() {
        let controller = PeripheralWriteViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

}
