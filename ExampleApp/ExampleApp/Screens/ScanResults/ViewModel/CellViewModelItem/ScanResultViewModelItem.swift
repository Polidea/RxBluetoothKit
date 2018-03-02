import RxBluetoothKit
import UIKit

class ScanResultsViewModelItem: SectionModelItem {

    var rowData: [Any] {
        return peripheralRowItems
    }

    var itemsCount: Int {
        return peripheralRowItems.count
    }

    var sectionName: String?

    private(set) var peripheralRowItems: [ScannedPeripheral]

    init(_ sectionName: String, peripheralRowItems: [ScannedPeripheral] = []) {
        self.sectionName = sectionName
        self.peripheralRowItems = peripheralRowItems
    }

    func cellClass() -> UIView.Type {
        return ScanResultTableViewCell.self
    }

   func append(_ item: Any) {
        if let item = item as? ScannedPeripheral {
            peripheralRowItems.append(item)
        }
    }
}
