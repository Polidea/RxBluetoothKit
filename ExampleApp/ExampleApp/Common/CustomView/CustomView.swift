import UIKit

public protocol CustomView {

    associatedtype ViewClass: UIView

    var customView: ViewClass { get }
}

extension CustomView where Self: UIViewController {

    public var customView: ViewClass {
        return (self.view as? ViewClass)!
    }
}
