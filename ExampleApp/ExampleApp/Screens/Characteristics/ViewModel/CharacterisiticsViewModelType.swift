import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {

    var characteristicsOutput: Observable<Characteristic> { get }

    var dataUpdateOutput: Observable<Void> { get }

    var characteristicWriteOutput: Observable<Result<Characteristic, Error>> { get }

    var characteristicReadOutput: Observable<Result<Characteristic, Error>> { get }

    func setSelected(characteristic: Characteristic)

    func triggerValueRead()

    func writeToCharacteristic(value: String)

    func setNotificationsState(enabled: Bool)

}
