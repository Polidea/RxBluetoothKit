import RxBluetoothKit
import Foundation

final class PeripheralServicesViewModelItem: SectionModelItem {

    typealias DataModelType = Service

    var rowData: [DataModelType] {
        return serviceRowItems
    }

    var itemsCount: Int {
        return serviceRowItems.count
    }

    var sectionName: String?

    private(set) var serviceRowItems: [DataModelType] = []

    init(_ sectionName: String) {
        self.sectionName = sectionName
    }

    var cellClass: PeripheralServiceCell.Type {
        return PeripheralServiceCell.self
    }

    func append(_ item: DataModelType) {
        let identicalService = serviceRowItems.filter {
            $0.service == item.service
        }

        guard identicalService.isEmpty else {
            return
        }

        serviceRowItems.append(item)
    }
}
