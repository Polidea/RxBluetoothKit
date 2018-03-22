import UIKit

class BaseView: UIView {

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140.0
        tableView.separatorStyle = .none
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(frame: .zero)
        indicatorView.hidesWhenStopped = true
        indicatorView.isHidden = true
        indicatorView.color = .blue
        return indicatorView
    }()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupConstraints()

    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleActivityIndicator(_ toggle: Bool) {
        if toggle {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func setTableView(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
        self.tableView.dataSource = dataSource
        self.tableView.delegate = delegate
    }

    func register(cellType: UITableViewCell.Type, forCellReuseIdentifier identifier: String) {
        tableView.register(cellType, forCellReuseIdentifier: identifier)
    }

    func indexPath(for cell: UITableViewCell) -> IndexPath? {
        return tableView.indexPath(for: cell)
    }

    func refreshTableView() {
        tableView.reloadData()
    }

    private func addSubviews() {
        [tableView, activityIndicator].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    private func setupConstraints() {
        tableView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
