import UIKit

class CentralViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - View

    private(set) lazy var centralView = CentralView()

    override func loadView() {
        view = centralView
    }

}
