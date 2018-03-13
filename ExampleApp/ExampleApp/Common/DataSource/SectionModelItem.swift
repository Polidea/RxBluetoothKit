import UIKit

protocol SectionModelItem {

    associatedtype ModelDataType

    var itemsCount: Int { get }

    var sectionName: String? { get }

    var rowData: [ModelDataType] { get }

    var cellClass: UIView.Type { get }

    func append(_ item: ModelDataType)
}
