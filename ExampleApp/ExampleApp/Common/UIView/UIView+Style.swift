import UIKit

extension UIView {

    public convenience init<V>(style: Style<V>) {
        self.init(frame: .zero)
        apply(style)
    }

    public func apply<V>(_ style: Style<V>) {
        guard let view = self as? V else {
            print("Could not apply style for \(V.self) to \(type(of: self))")
            return
        }
        style.apply(to: view)
    }
}
