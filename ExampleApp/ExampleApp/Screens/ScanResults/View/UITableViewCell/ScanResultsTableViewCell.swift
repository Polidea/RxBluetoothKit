import RxBluetoothKit
import UIKit

class ScanResultTableViewCell: UITableViewCell {

    private let peripheralNameLabel: UILabel = UILabel(style: Stylesheet.Commons.titleLabel)
    
    private let advertisementDataLabel: UILabel = UILabel(style: Stylesheet.Commons.descriptionLabel)
    
    private let rssiLabel: UILabel = UILabel(style: Stylesheet.Commons.descriptionLabel)
    
    private let bluetoothImageView: UIImageView = UIImageView(image: UIImage(named: "bluetooth"))

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        applyStyles()
        setConstraints()
        backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        peripheralNameLabel.text = nil
        advertisementDataLabel.text = nil
        rssiLabel.text = nil
    }

    private func applyStyles() {
        Stylesheet.Commons.cellSmallImageRound.apply(to: bluetoothImageView)
    }

    private func setConstraints() {
        [peripheralNameLabel, advertisementDataLabel, bluetoothImageView, rssiLabel].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        addSubview(bluetoothImageView)

        bluetoothImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20.0).isActive = true
        bluetoothImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        bluetoothImageView.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        bluetoothImageView.widthAnchor.constraint(equalToConstant: 32.0).isActive = true

        peripheralNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12.0).isActive = true
        peripheralNameLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: 16.0).isActive = true
        
        advertisementDataLabel.topAnchor.constraint(equalTo: peripheralNameLabel.bottomAnchor, constant: 12.0).isActive = true
        advertisementDataLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: 16.0).isActive = true
        advertisementDataLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16).isActive = true
        
        rssiLabel.topAnchor.constraint(equalTo: advertisementDataLabel.bottomAnchor, constant: 12.0).isActive = true
        rssiLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: 16.0).isActive = true
        rssiLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16.0).isActive = true
        rssiLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

extension ScanResultTableViewCell: UpdatableCell {
    func update(with item: Any) {
        guard let item = item as? ScannedPeripheral else {
            return
        }

        peripheralNameLabel.text = item.advertisementData.localName ?? item.peripheral.identifier.uuidString
        advertisementDataLabel.text = "\(item.advertisementData.advertisementData)"
        rssiLabel.text = "RSSI: \(item.rssi)"
    }
}
