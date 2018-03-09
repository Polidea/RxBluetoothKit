import RxBluetoothKit
import UIKit

class PeripheralServiceCell: UITableViewCell, UpdatableCell {

    private let uuidLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)
    private let isPrimaryLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)
    private let bluetoothImageView: UIImageView = UIImageView(image: UIImage(named: "bluetooth-service"))

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        [uuidLabel, isPrimaryLabel, bluetoothImageView].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        bluetoothImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        bluetoothImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        bluetoothImageView.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        bluetoothImageView.widthAnchor.constraint(equalToConstant: 32.0).isActive = true

        uuidLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16.0).isActive = true
        uuidLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: 8.0).isActive = true
        uuidLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8.0).isActive = true

        isPrimaryLabel.topAnchor.constraint(equalTo: self.uuidLabel.bottomAnchor, constant: 8).isActive = true
        isPrimaryLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: 8.0).isActive = true
        isPrimaryLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8.0).isActive = true
    }

    func update(with item: Any) {
        guard let item = item as? Service else { return }
        uuidLabel.text = String(describing: item.uuid)
        isPrimaryLabel.text = "Is primary: \(item.isPrimary)"
    }
}
