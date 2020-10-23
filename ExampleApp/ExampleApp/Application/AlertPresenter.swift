import UIKit

class AlertPresenter {

    static func presentError(with message: String, on viewController: UIViewController?) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "Ok",
                style: .cancel,
                handler: { action in
                    viewController?.dismiss(animated: true)
                }
            )
        )
        viewController?.present(alert, animated: true)
    }

}
