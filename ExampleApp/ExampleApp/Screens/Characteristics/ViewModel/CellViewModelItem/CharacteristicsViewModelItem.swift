import RxBluetoothKit
import UIKit

class CharacteristicsViewModelItem: SectionModelItem {

    var rowData: [Any] {
        return characteristicsRowItems
    }

    var itemsCount: Int {
        return characteristicsRowItems.count
    }

    var sectionName: String?

    private(set) var characteristicsRowItems: [Characteristic]

    init(_ sectionName: String, characteristicsRowItems: [Characteristic]?) {
        self.sectionName = sectionName
        self.characteristicsRowItems = characteristicsRowItems ?? []
    }

    func cellClass() -> UIView.Type {
        return CharacterisiticsTableViewCell.self
    }

    func append(_ item: Any) {
        guard let item = item as? [Characteristic] else { return }
        characteristicsRowItems.append(contentsOf: item)
    }
}
