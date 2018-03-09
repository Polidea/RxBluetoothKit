import Foundation
import RxBluetoothKit
import RxCocoa
import RxSwift

protocol CharacteristicsViewModelType {

    var characteristicsOutput: Observable<[Characteristic]> { get }

    func setCurrent(characteristic: Characteristic)

    func triggerValueRead()

    func writeValueForCharacteristic(hexadecimalString: String)

    func setNotificationsState(enabled: Bool)
}
