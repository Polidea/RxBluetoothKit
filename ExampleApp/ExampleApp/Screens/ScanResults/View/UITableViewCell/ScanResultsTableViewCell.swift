import RxBluetoothKit
import UIKit

class ScanResultTableViewCell: UITableViewCell {

    private let peripheralNameLabel: UILabel = UILabel(frame: .zero)
    private let advertisementDataLabel: UILabel = UILabel(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setConstraints()
        backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        [peripheralNameLabel, advertisementDataLabel].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        peripheralNameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        peripheralNameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        advertisementDataLabel.topAnchor.constraint(equalTo: self.peripheralNameLabel.bottomAnchor, constant: 8).isActive = true
        advertisementDataLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
    }
}

extension ScanResultTableViewCell: UpdatableCell {
    func update(with item: Any) {
        guard let item = item as? ScannedPeripheral else {
            return
        }

        peripheralNameLabel.text = item.advertisementData.localName ?? item.peripheral.identifier.uuidString
        advertisementDataLabel.text = "\(item.advertisementData.advertisementData)"
    }
}
