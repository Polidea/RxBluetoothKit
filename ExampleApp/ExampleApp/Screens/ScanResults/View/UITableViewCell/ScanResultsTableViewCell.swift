import RxBluetoothKit
import UIKit

final class ScanResultTableViewCell: UITableViewCell {

    private let peripheralNameLabel = UILabel(style: Stylesheet.Commons.titleLabel)

    private let advertisementDataLabel = UILabel(style: Stylesheet.Commons.descriptionLabel)

    private let rssiLabel = UILabel(style: Stylesheet.Commons.descriptionLabel)

    private let bluetoothImageView = UIImageView(image: Constant.ImageRepo.bluetooth)

    private let connectButton = UIButton(style: Stylesheet.Commons.connectButton)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        applyStyles()
        setConstraints()
        backgroundColor = .white
        selectionStyle = .none
        connectButton.setTitle("Connect", for: .normal)
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

    func setConnectTarget(_ target: Any, action: Selector, for events: UIControlEvents) {
        if connectButton.allTargets.isEmpty {
            connectButton.addTarget(target, action: action, for: events)
        }
    }

    private func applyStyles() {
        Stylesheet.Commons.cellSmallImageRound.apply(to: bluetoothImageView)
    }

    private func setConstraints() {
        [peripheralNameLabel, advertisementDataLabel, bluetoothImageView, rssiLabel, connectButton].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        bluetoothImageView.topAnchor.constraint(equalTo: topAnchor, constant: Constant.Constraints.verticalMedium).isActive = true
        bluetoothImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constant.Constraints.horizontalSmall).isActive = true
        bluetoothImageView.heightAnchor.constraint(equalToConstant: Constant.Constraints.smallHeight).isActive = true
        bluetoothImageView.widthAnchor.constraint(equalToConstant: Constant.Constraints.smallWidth).isActive = true

        peripheralNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        peripheralNameLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: Constant.Constraints.horizontalDefault).isActive = true

        advertisementDataLabel.topAnchor.constraint(equalTo: peripheralNameLabel.bottomAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        advertisementDataLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: Constant.Constraints.horizontalDefault).isActive = true
        advertisementDataLabel.rightAnchor.constraint(equalTo: connectButton.leftAnchor, constant: -Constant.Constraints.horizontalDefault).isActive = true

        rssiLabel.topAnchor.constraint(equalTo: advertisementDataLabel.bottomAnchor, constant: Constant.Constraints.verticalDefault).isActive = true
        rssiLabel.leftAnchor.constraint(equalTo: bluetoothImageView.rightAnchor, constant: Constant.Constraints.horizontalDefault).isActive = true
        rssiLabel.rightAnchor.constraint(equalTo: connectButton.leftAnchor, constant: -Constant.Constraints.horizontalDefault).isActive = true

        connectButton.topAnchor.constraint(equalTo: rssiLabel.bottomAnchor, constant: Constant.Constraints.verticalSmall).isActive = true
        connectButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constant.Constraints.horizontalDefault).isActive = true
        connectButton.heightAnchor.constraint(equalToConstant: Constant.Constraints.smallHeight).isActive = true
        connectButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constant.Constraints.verticalSmall).isActive = true
    }
}

extension ScanResultTableViewCell: UpdatableCell {

    func update(with item: ScannedPeripheral) {
        peripheralNameLabel.text = item.advertisementData.localName ?? item.peripheral.identifier.uuidString
        advertisementDataLabel.text = "\(item.advertisementData.advertisementData)"
        rssiLabel.text = "RSSI: \(item.rssi)"
        let style = item.peripheral.isConnected ? Stylesheet.Commons.connectedButton : Stylesheet.Commons.connectButton
        connectButton.apply(style)
    }
}
