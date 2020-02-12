import TinkLinkSDK
import UIKit

/// Example of how to use the provider grouped by names
final class ProviderListViewController: UITableViewController {

    weak var addCredentialNavigator: AddCredentialFlowNavigating?

    private var providerController: ProviderController?

    private let searchController = UISearchController(searchResultsController: nil)
    private var originalFinancialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode] = []
    private var financialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    init(providerController: ProviderController) {
        self.providerController = providerController
        financialInstitutionGroupNodes = providerController.financialInstitutionGroupNodes

        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Lifecycle

extension ProviderListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateProviders), name: .providerControllerDidUpdateProviders, object: nil)

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchResultsUpdater = self

        // TODO: navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        definesPresentationContext = true

        title = "Choose Bank"

        tableView.register(ProviderCell.self, forCellReuseIdentifier: "Cell")

        tableView.backgroundColor = Color.background
        tableView.separatorColor = Color.separator
    }

    @objc private func updateProviders() {
        DispatchQueue.main.async {
            self.financialInstitutionGroupNodes = self.providerController?.financialInstitutionGroupNodes ?? []
        }
    }

    @objc private func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ProviderListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return financialInstitutionGroupNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let group = financialInstitutionGroupNodes[indexPath.row]
        if let imageViewCell = cell as? ProviderCell {
            imageViewCell.setTitle(text: group.displayName)
            if let url = group.imageURL {
                imageViewCell.setImage(url: url)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let financialInstitutionGroupNode = financialInstitutionGroupNodes[indexPath.row]
        switch financialInstitutionGroupNode {
        case .financialInstitutions(let financialInstitutionGroups):
            addCredentialNavigator?.showFinancialInstitution(for: financialInstitutionGroups, title: financialInstitutionGroupNode.displayName)
        case .accessTypes(let accessTypeGroups):
            addCredentialNavigator?.showAccessTypePicker(for: accessTypeGroups, title: financialInstitutionGroupNode.displayName)
        case .credentialKinds(let groups):
            addCredentialNavigator?.showCredentialKindPicker(for: groups, title: nil)
        case .provider(let provider):
            addCredentialNavigator?.showAddCredential(for: provider)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ProviderListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            financialInstitutionGroupNodes = originalFinancialInstitutionGroupNodes.filter { $0.displayName.localizedCaseInsensitiveContains(text) }
        } else {
            financialInstitutionGroupNodes = originalFinancialInstitutionGroupNodes
        }
    }
}
