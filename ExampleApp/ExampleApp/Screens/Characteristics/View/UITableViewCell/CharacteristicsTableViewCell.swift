import RxBluetoothKit
import UIKit

class CharacterisiticsTableViewCell: UITableViewCell {

    let uuidLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)

    let isNotyfingLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)

    let valueLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)

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

        uuidLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8.0).isActive = true
        uuidLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        uuidLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8.0).isActive = true

        isNotyfingLabel.topAnchor.constraint(equalTo: uuidLabel.bottomAnchor, constant: 8.0).isActive = true
        isNotyfingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        isNotyfingLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8.0).isActive = true

        valueLabel.topAnchor.constraint(equalTo: isNotyfingLabel.bottomAnchor, constant: 8.0).isActive = true
        valueLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        valueLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8.0).isActive = true
        valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

extension CharacterisiticsTableViewCell: UpdatableCell {

    func update(with item: Any) {
        guard let item = item as? Characteristic else { return }
        let uuid = item.uuid.uuidString ?? ""
        let value = item.value?.hexadecimalString ?? "No value"
        uuidLabel.text = "UUID: \(uuid)"
        isNotyfingLabel.text = "Is notyfying: \(item.isNotifying)"
        valueLabel.text = "Value: \(value)"
    }
}
