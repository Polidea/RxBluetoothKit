import UIKit

protocol Presenter {
    var viewController: UIViewController? { get set }

    func present(viewController: UIViewController)
    func dismiss(viewController: UIViewController)
    func push(viewController: UIViewController)
}

class ViewControllerPresenter: Presenter {

    weak var viewController: UIViewController?

    func present(viewController: UIViewController) {
        self.viewController?.present(viewController, animated: false, completion: nil)
    }

    func dismiss(viewController: UIViewController) {
        viewController.dismiss(animated: false, completion: nil)
    }

    func push(viewController: UIViewController) {
        guard let navigationVC = self.viewController as? UINavigationController else { return }
        navigationVC.pushViewController(viewController, animated: false)
    }
}
