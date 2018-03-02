import UIKit

class ScanResultsView: UIView {

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        return tableView
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
