import RxBluetoothKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let dataItem: ScanResultsViewModelItem = ScanResultsViewModelItem(Constant.Strings.scanResultSectionTitle)
        let configureBlock: (UITableViewCell, Any) -> Void = { (cell, item) in
            guard let cell = cell as? UpdatableCell else { return }
            cell.update(with: item)
        }

        let scanResultsDataSource = TableViewDataSource<ScannedPeripheral, ScanResultsViewModelItem>(dataItem: dataItem, configureBlock: configureBlock)
        let viewModel = ScanResultsViewModel(with: RxBluetoothKitService())
        let scanResultsViewController = ScanResultsViewController(with: scanResultsDataSource, viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: scanResultsViewController)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}
