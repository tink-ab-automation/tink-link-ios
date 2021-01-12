import UIKit
import TinkLink

final class FinancialInstitutionSearchViewController: UITableViewController {
    weak var providerPickerCoordinator: ProviderPickerCoordinating?

    var originalFinancialInstitutionNodes: [ProviderTree.FinancialInstitutionNode] = []

    private var financialInstitutionNodes: [ProviderTree.FinancialInstitutionNode] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    init() {
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Lifecycle

extension FinancialInstitutionSearchViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.background
        tableView.registerReusableCell(ofType: ProviderCell.self)
        tableView.tableFooterView = UIView(frame: .zero)
    }
}

// MARK: - UITableViewDataSource

extension FinancialInstitutionSearchViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return financialInstitutionNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = financialInstitutionNodes[indexPath.row]

        let cell = tableView.dequeueReusableCell(ofType: ProviderCell.self, for: indexPath)
        cell.setTitle(text: node.financialInstitution.name)
        if let url = node.imageURL {
            cell.setImage(url: url)
        }
        let isBeta = node.providers.contains(where: { $0.releaseStatus == .beta })
        cell.setBetaLabelHidden(!isBeta)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let financialInstitutionNode = financialInstitutionNodes[indexPath.row]
        switch financialInstitutionNode {
        case .authenticationUserTypes(let authenticationUserTypeGroups):
            providerPickerCoordinator?.showAuthenticationUserTypePicker(for: authenticationUserTypeGroups)
        case .accessTypes(let accessTypeGroups):
            providerPickerCoordinator?.showAccessTypePicker(for: accessTypeGroups, name: financialInstitutionNode.financialInstitution.name)
        case .credentialsKinds(let groups):
            providerPickerCoordinator?.showCredentialsKindPicker(for: groups)
        case .provider(let provider):
            providerPickerCoordinator?.didSelectProvider(provider)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension FinancialInstitutionSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            financialInstitutionNodes = searchFinancialInstitution(with: text)
        } else {
            financialInstitutionNodes = originalFinancialInstitutionNodes
        }
    }

    private func searchFinancialInstitution(with query: String) -> [ProviderTree.FinancialInstitutionNode] {
        let foldedQuery = query.folding(options: .diacriticInsensitive, locale: Tink.defaultLocale)
        var filteredFinancialInstitutionNodes = originalFinancialInstitutionNodes
        for component in foldedQuery.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            if !component.isEmpty {
                filteredFinancialInstitutionNodes = filteredFinancialInstitutionNodes.filter {
                    let foldedProviderName = $0.financialInstitution.name.folding(options: .diacriticInsensitive, locale: Tink.defaultLocale)
                    return foldedProviderName.localizedCaseInsensitiveContains(component)
                }
            }
        }
        return filteredFinancialInstitutionNodes
    }
}
