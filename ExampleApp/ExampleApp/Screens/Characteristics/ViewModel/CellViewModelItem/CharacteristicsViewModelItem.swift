import RxBluetoothKit
import UIKit

class CharacteristicsViewModelItem: SectionModelItem {

    typealias ModelDataType = Characteristic

    var rowData: [ModelDataType] {
        return characteristicsRowItems
    }

    var itemsCount: Int {
        return characteristicsRowItems.count
    }

    var sectionName: String?

    var cellClass: CharacterisiticsTableViewCell.Type {
        return CharacterisiticsTableViewCell.self
    }

    private(set) var characteristicsRowItems: [ModelDataType]

    init(_ sectionName: String, characteristicsRowItems: [ModelDataType]?) {
        self.sectionName = sectionName
        self.characteristicsRowItems = characteristicsRowItems ?? []
    }

    func append(_ item: ModelDataType) {
        let identicalCharacteristic = characteristicsRowItems.filter {
            $0.characteristic == item.characteristic
        }

        guard identicalCharacteristic.isEmpty else {
            return
        }

        characteristicsRowItems.append(item)
    }
}
