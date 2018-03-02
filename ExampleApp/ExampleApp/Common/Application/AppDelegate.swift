import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let scanResultsViewController = ScanResultsViewController(with: TableViewDataSource { cell, item in
            guard let cell = cell as? UpdatableCell else { return }
            cell.update(with: item)
        })
        let navigationController = UINavigationController(rootViewController: scanResultsViewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        return true
    }
}
