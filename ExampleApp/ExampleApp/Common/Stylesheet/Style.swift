import UIKit

public struct Style<View:UIView> {

    public let style: (View) -> Void

    public init(_ style: @escaping (View) -> Void) {
        self.style = style
    }

    public func apply(to view: View) {
        style(view)
    }
}
