import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {

    var characteristicsOutput: Observable<Characteristic> { get }

    var dataUpdateOutput: Observable<Void> { get }

    var alertTriggerOutput: Observable<String> { get }

    func setSelected(characteristic: Characteristic)

    func triggerValueRead()

    func writeValueForCharacteristic(hexadecimalString: String)

    func setNotificationsState(enabled: Bool)

}
