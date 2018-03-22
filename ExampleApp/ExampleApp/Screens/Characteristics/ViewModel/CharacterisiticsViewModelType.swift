import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {

    var characteristicsOutput: Observable<Characteristic> { get }

    var dataUpdateOutput: Observable<Void> { get }

    var alertTriggerOutput: Observable<AlertResult> { get }

    var characteristicWriteValue: Observable<Result<Characteristic, BluetoothError>> { get }

    func setSelected(characteristic: Characteristic)

    func triggerValueRead()

    func writeToCharacteristic(value: String)

    func setNotificationsState(enabled: Bool)

}
