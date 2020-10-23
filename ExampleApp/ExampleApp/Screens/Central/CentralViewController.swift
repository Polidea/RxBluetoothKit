import UIKit

class CentralViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    private(set) lazy var centralView = CentralView()

    override func loadView() {
        view = centralView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        centralView.specificButton.addTarget(self, action: #selector(handleSpecificButtonTap), for: .touchUpInside)
        centralView.listButton.addTarget(self, action: #selector(handleListButtonTap), for: .touchUpInside)
    }

    @objc func handleSpecificButtonTap() {
        let controller = CentralSpecificViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func handleListButtonTap() {
        let controller = CentralListViewController()
        navigationController?.pushViewController(controller, animated: true)
    }

}
