import UIKit

protocol Presenter {
    var viewController: UIViewController? { get set }

    func present(viewController: UIViewController)
    func dismiss(viewController: UIViewController)
}
