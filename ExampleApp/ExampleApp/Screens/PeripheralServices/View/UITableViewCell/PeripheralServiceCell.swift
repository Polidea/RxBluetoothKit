import RxBluetoothKit
import UIKit

final class PeripheralServiceCell: UITableViewCell, UpdatableCell {

    private let uuidLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    private let isPrimaryLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    private let bluetoothImageView = UIImageView(image: Constant.ImageRepo.bluetoothService)

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
        bluetoothImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        bluetoothImageView.heightAnchor.constraint(equalToConstant: Constant.Constraints.smallWidth).isActive = true
        bluetoothImageView.widthAnchor.constraint(equalToConstant: Constant.Constraints.smallHeight).isActive = true

        uuidLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        uuidLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        uuidLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalSmall).isActive = true

        isPrimaryLabel.topAnchor.constraint(equalTo: self.uuidLabel.bottomAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        isPrimaryLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        isPrimaryLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalSmall).isActive = true
    }

    func update(with item: Service) {
        uuidLabel.text = String(describing: item.uuid)
        isPrimaryLabel.text = "Is primary: \(item.isPrimary)"
    }
}
