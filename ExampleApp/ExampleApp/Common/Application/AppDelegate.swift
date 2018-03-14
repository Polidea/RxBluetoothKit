import RxBluetoothKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let navigationController = prepareScanningScene()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }

    private func prepareScanningScene() -> UINavigationController {
        let dataItem = ScanResultsViewModelItem(Constant.Strings.scanResultSectionTitle)
        let scanResultsDataSource = TableViewDataSource<ScanResultsViewModelItem>(dataItem: dataItem)
        let viewModel = ScanResultsViewModel(with: RxBluetoothKitService())
        let scanResultsViewController = ScanResultsViewController(with: scanResultsDataSource, viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: scanResultsViewController)
        return navigationController
    }
}
