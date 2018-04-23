import RxBluetoothKit
import UIKit

class CharacterisiticsTableViewCell: UITableViewCell {

    let uuidLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    let isNotyfingLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    let valueLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        setConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        uuidLabel.text = nil
        isNotyfingLabel.text = nil
        valueLabel.text = nil
    }

    private func setConstraints() {
        [uuidLabel, isNotyfingLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        uuidLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        uuidLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        uuidLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalSmall).isActive = true

        isNotyfingLabel.topAnchor.constraint(equalTo: uuidLabel.bottomAnchor, constant: Constant.Constraints.verticalSmall).isActive = true
        isNotyfingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        isNotyfingLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalSmall).isActive = true

        valueLabel.topAnchor.constraint(equalTo: isNotyfingLabel.bottomAnchor, constant: Constant.Constraints.verticalSmall).isActive = true
        valueLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        valueLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalSmall).isActive = true
        valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constant.Constraints.verticalDefault).isActive = true
    }
}

extension CharacterisiticsTableViewCell: UpdatableCell {

    func update(with item: Characteristic) {
        let uuid = item.uuid.uuidString
        let value = item.value?.hexadecimalString ?? "No value"
        uuidLabel.text = "UUID: \(uuid)"
        isNotyfingLabel.text = "Is notyfying: \(item.isNotifying)"
        valueLabel.text = "Value: \(value)"
    }
}
