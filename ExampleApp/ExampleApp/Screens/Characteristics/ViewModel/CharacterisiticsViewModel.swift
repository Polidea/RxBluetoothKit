import Foundation
import RxBluetoothKit
import RxSwift

class CharacteristicsViewModel: CharacteristicsViewModelType {

    var characteristicsOutput: Observable<[Characteristic]> {
        return bluetoothService.discoverCharacteristics()
    }

    private let bluetoothService: RxBluetoothKitService = RxBluetoothKitService.shared

    init() {

    }
}
