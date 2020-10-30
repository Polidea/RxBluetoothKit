import RxBluetoothKit
import CoreBluetooth

struct CharacteristicInfo: Identifiable, Equatable {
    let id: CBUUID
    let value: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension CharacteristicInfo {

    func withValue(_ value: String) -> CharacteristicInfo {
        return .init(id: id, value: value)
    }

}
