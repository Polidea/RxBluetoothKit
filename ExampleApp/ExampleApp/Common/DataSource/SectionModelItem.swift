import UIKit

protocol SectionModelItem {

    typealias UpdatableTableViewCell = UITableViewCell & UpdatableCell

    associatedtype CellType : UpdatableTableViewCell

    typealias ModelDataType = CellType.ModelDataType

    var itemsCount: Int { get }

    var sectionName: String? { get }

    var rowData: [ModelDataType] { get }

    var cellClass: CellType.Type { get }

    func append(_ item: ModelDataType)
}
