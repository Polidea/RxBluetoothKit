import UIKit

protocol SectionModelItem {

    var itemsCount: Int { get }

    var sectionName: String? { get }

    var rowData: [Any] { get }

    func cellClass() -> UIView.Type
}

extension SectionModelItem {

    var itemsCount: Int {
        return 1
    }

    var rowData: [Any] {
        return []
    }
}