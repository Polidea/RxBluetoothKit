import UIKit

class ScanResultsView: UIView {

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        return tableView
    }()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupConstraints()
        backgroundColor = .green
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTableView(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
        self.tableView.dataSource = dataSource
        self.tableView.delegate = delegate
    }
    
    func refreshTableView() {
        tableView.reloadData()
    }

    private func addSubviews() {
        [tableView].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
}
