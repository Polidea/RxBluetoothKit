import UIKit

protocol SectionModelItem {

    var itemsCount: Int { get }

    var sectionName: String? { get }

    var rowData: [Any] { get }

    func cellClass() -> UIView.Type

    func append(_ item: Any)
}

extension SectionModelItem {

    var itemsCount: Int {
        return rowData.count
    }

    var rowData: [Any] {
        return []
    }
}
