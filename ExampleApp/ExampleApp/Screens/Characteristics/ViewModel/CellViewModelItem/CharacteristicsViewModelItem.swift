import RxBluetoothKit
import UIKit

class CharacterisiticsViewModelItem: SectionModelItem {

    var rowData: [Any] {
        return characteristicsRowItems
    }

    var itemsCount: Int {
        return characteristicsRowItems.count
    }

    var sectionName: String?

    private(set) var characteristicsRowItems: [Characteristic]

    init(_ sectionName: String, peripheralRowItems: [Characteristic] = []) {
        self.sectionName = sectionName
        self.characteristicsRowItems = peripheralRowItems
    }

    func cellClass() -> UIView.Type {
        return CharacterisiticsTableViewCell.self
    }

    func append(_ item: Any) {
        //TODO
    }
}
