import UIKit

class TableViewDataSource: NSObject, UITableViewDataSource {

    typealias CellConfigurationBlock = (_ cell: UITableViewCell, _ item: Any) -> Void

    private var configureBlock: CellConfigurationBlock

    private var elements: [SectionModelItem]

    init(elements: [SectionModelItem], configureBlock: @escaping CellConfigurationBlock ){
        self.elements = elements
        self.configureBlock = configureBlock
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return elements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
