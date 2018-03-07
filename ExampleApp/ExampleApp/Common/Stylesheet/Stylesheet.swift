import UIKit

enum Stylesheet {

    enum Commons {

        static let boldLabel = Style<UILabel> {
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = .red
        }

        static let cellSmallImageRound = Style<UIImageView> {
            $0.contentMode = .scaleAspectFit
            $0.backgroundColor = .white
            $0.tintColor = .blue
            $0.clipsToBounds = true
        }
    }
}