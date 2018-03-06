import RxBluetoothKit
import UIKit

class PeripheralServiceCell: UITableViewCell, UpdatableCell {

    private let uuidLabel: UILabel = UILabel(frame: .zero)
    private let isPrimaryLabel: UILabel = UILabel(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        backgroundColor = .yellow
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setConstraints() {
        [uuidLabel, isPrimaryLabel].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        uuidLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        uuidLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        isPrimaryLabel.topAnchor.constraint(equalTo: self.uuidLabel.bottomAnchor, constant: 8).isActive = true
        isPrimaryLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
    }

    func update(with item: Any) {
        guard let item = item as? Service else { return }
        uuidLabel.text = String(describing: item.uuid)
        isPrimaryLabel.text = "Is primary: \(item.isPrimary)"
    }
}
