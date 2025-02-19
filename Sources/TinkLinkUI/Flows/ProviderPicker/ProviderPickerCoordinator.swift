import UIKit
import TinkLink

protocol ProviderPickerCoordinating: AnyObject {
    func showFinancialInstitutionGroupNodes(for financialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode], title: String?)
    func showFinancialInstitution(for financialInstitutionNodes: [ProviderTree.FinancialInstitutionNode], name: String)
    func showFinancialServicesPicker(for financialServicesNodes: [ProviderTree.FinancialServicesNode])
    func showAccessTypePicker(for accessTypeNodes: [ProviderTree.AccessTypeNode], name: String)
    func showCredentialsKindPicker(for credentialsKindNodes: [ProviderTree.CredentialsKindNode])
    func didSelectProvider(_ provider: Provider)
}

class ProviderPickerCoordinator: ProviderPickerCoordinating {
    private let tinkLinkTracker: TinkLinkTracker
    private let providerController: ProviderController
    private weak var parentViewController: UIViewController?
    private var completion: ((Result<Provider, Error>) -> Void)?

    init(parentViewController: UIViewController, providerController: ProviderController, tinkLinkTracker: TinkLinkTracker) {
        self.providerController = providerController
        self.parentViewController = parentViewController
        self.tinkLinkTracker = tinkLinkTracker
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start(completion: @escaping ((Result<Provider, Error>) -> Void)) {
        DispatchQueue.main.async {
            self.showFinancialInstitutionGroupNodes(for: self.providerController.financialInstitutionGroupNodes, title: Strings.ProviderList.title)
        }

        self.completion = completion
    }

    private func setupNavigationItem(for viewController: UIViewController, title: String?) {
        viewController.title = title
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }

    @objc func cancel() {
        completion?(.failure(TinkLinkUIError(code: .userCancelled)))
    }

    func showFinancialInstitutionGroupNodes(for financialInstitutionGroupNodes: [ProviderTree.FinancialInstitutionGroupNode], title: String?) {
        tinkLinkTracker.providerID = nil
        let providerListViewController = ProviderListViewController(financialInstitutionGroupNodes: financialInstitutionGroupNodes)
        providerListViewController.navigationItem.hidesBackButton = true
        setupNavigationItem(for: providerListViewController, title: title)
        providerListViewController.providerPickerCoordinator = self
        tinkLinkTracker.track(screen: .financialInstitutionSelection)
        UIView.performWithoutAnimation {
            self.parentViewController?.show(providerListViewController, sender: self)
        }
    }

    func showFinancialInstitution(for financialInstitutionNodes: [ProviderTree.FinancialInstitutionNode], name: String) {
        tinkLinkTracker.providerID = nil
        let viewController = FinancialInstitutionPickerViewController(financialInstitutionNodes: financialInstitutionNodes, tinkLinkTracker: tinkLinkTracker)
        setupNavigationItem(for: viewController, title: name)
        viewController.providerPickerCoordinator = self
        tinkLinkTracker.track(screen: .providerSelection)
        parentViewController?.show(viewController, sender: nil)
    }

    func showFinancialServicesPicker(for financialServicesTypeNodes: [ProviderTree.FinancialServicesNode]) {
        tinkLinkTracker.providerID = nil
        let viewController = FinancialServicesTypePickerViewController(financialServicesTypeNodes: financialServicesTypeNodes, tinkLinkTracker: tinkLinkTracker)
        let title = Strings.SelectAuthenticationUserType.title
        setupNavigationItem(for: viewController, title: title)
        viewController.providerPickerCoordinator = self
        tinkLinkTracker.track(screen: .authenticationUserTypeSelection)
        parentViewController?.show(viewController, sender: nil)
    }

    func showAccessTypePicker(for accessTypeNodes: [ProviderTree.AccessTypeNode], name: String) {
        tinkLinkTracker.providerID = nil
        let viewController = AccessTypePickerViewController(accessTypeNodes: accessTypeNodes, tinkLinkTracker: tinkLinkTracker)
        let title = Strings.SelectAccessType.title
        setupNavigationItem(for: viewController, title: title)
        viewController.providerPickerCoordinator = self
        tinkLinkTracker.track(screen: .accessTypeSelection)
        parentViewController?.show(viewController, sender: nil)
    }

    func showCredentialsKindPicker(for credentialsKindNodes: [ProviderTree.CredentialsKindNode]) {
        tinkLinkTracker.providerID = nil
        let viewController = CredentialsKindPickerViewController(credentialsKindNodes: credentialsKindNodes, tinkLinkTracker: tinkLinkTracker)
        let title = Strings.SelectCredentialsType.title
        setupNavigationItem(for: viewController, title: title)
        viewController.providerPickerCoordinator = self
        tinkLinkTracker.track(screen: .credentialsTypeSelection)
        parentViewController?.show(viewController, sender: nil)
    }

    func didSelectProvider(_ provider: Provider) {
        completion?(.success(provider))
    }
}
