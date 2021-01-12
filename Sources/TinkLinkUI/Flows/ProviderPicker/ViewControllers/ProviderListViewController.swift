import TinkLink
import UIKit

/// Example of how to use the provider grouped by names
final class ProviderListViewController: UITableViewController {
    weak var providerPickerCoordinator: ProviderPickerCoordinating?

    private let searchViewController = FinancialInstitutionSearchViewController()

    private lazy var searchController = TinkSearchController(searchResultsController: searchViewController)

    private var financialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode]

    init(financialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode]) {
        self.financialInstitutionGroupNodes = financialInstitutionGroupNodes
        searchViewController.originalFinancialInstitutionNodes = financialInstitutionGroupNodes.makeFinancialInstitutions()
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Lifecycle

extension ProviderListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true

        searchViewController.providerPickerCoordinator = providerPickerCoordinator
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = Strings.ProviderList.searchHint
        searchController.searchResultsUpdater = searchViewController

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.registerReusableCell(ofType: ProviderCell.self)

        tableView.backgroundColor = Color.background
        tableView.separatorColor = Color.separator
    }
}

// MARK: - UITableViewDataSource

extension ProviderListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return financialInstitutionGroupNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = financialInstitutionGroupNodes[indexPath.row]

        let cell = tableView.dequeueReusableCell(ofType: ProviderCell.self, for: indexPath)
        cell.setTitle(text: group.displayName)
        if let url = group.imageURL {
            cell.setImage(url: url)
        }
        let isBeta = group.providers.contains(where: { $0.releaseStatus == .beta })
        cell.setBetaLabelHidden(!isBeta)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let financialInstitutionGroupNode = financialInstitutionGroupNodes[indexPath.row]
        switch financialInstitutionGroupNode {
        case .financialInstitutions(let financialInstitutionGroups):
            providerPickerCoordinator?.showFinancialInstitution(for: financialInstitutionGroups, name: financialInstitutionGroupNode.displayName)
        case .authenticationUserTypes(let authenticationUserTypeGroups):
            providerPickerCoordinator?.showAuthenticationUserTypePicker(for: authenticationUserTypeGroups)
        case .accessTypes(let accessTypeGroups):
            providerPickerCoordinator?.showAccessTypePicker(for: accessTypeGroups, name: financialInstitutionGroupNode.displayName)
        case .credentialsKinds(let groups):
            providerPickerCoordinator?.showCredentialsKindPicker(for: groups)
        case .provider(let provider):
            providerPickerCoordinator?.didSelectProvider(provider)
        }
    }
}
