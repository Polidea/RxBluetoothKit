import UIKit

class ScanResultsViewController: UIViewController, CustomView {

    typealias ViewClass = ScanResultsView

    override func loadView() {
        super.loadView()
        view = ViewClass()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
