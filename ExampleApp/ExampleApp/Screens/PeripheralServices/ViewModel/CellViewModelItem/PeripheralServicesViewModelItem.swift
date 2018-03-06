import RxBluetoothKit
import Foundation

class PeripheralServicesViewModelItem: SectionModelItem {

    var rowData: [Any] {
        return serviceRowItems
    }

    var itemsCount: Int {
        return serviceRowItems.count
    }

    var sectionName: String?

    private(set) var serviceRowItems: [Service]

    init(_ sectionName: String, peripheralRowItems: [Service]?) {
        self.sectionName = sectionName
        self.serviceRowItems = peripheralRowItems ?? []
    }

    func cellClass() -> UIView.Type {
        return PeripheralServiceCell.self
    }

    func append(_ item: Any) {
        if let item = item as? [Service] {
            serviceRowItems.append(contentsOf: item)
        }
    }
}
