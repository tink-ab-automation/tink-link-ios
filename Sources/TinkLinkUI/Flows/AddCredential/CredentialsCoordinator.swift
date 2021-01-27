import UIKit
import TinkLink

protocol CredentialsCoordinatorPresenting: AnyObject {
    func showLoadingIndicator(text: String?, onCancel: (() -> Void)?)
    func hideLoadingIndicator()
    func show(_ viewController: UIViewController)
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

protocol CredentialsCoordinatorDelegate: AnyObject {
    func didFinishCredentialsForm()
}

final class CredentialsCoordinator {
    enum AddCredentialsMode {
        case anonymous(scopes: [Scope])
        case user
    }

    enum Action {
        case create(provider: Provider, mode: AddCredentialsMode)
        case update(credentialsID: Credentials.ID)
        case refresh(credentialsID: Credentials.ID, forceAuthenticate: Bool = false)
        case authenticate(credentialsID: Credentials.ID)
    }

    var prefillStrategy: TinkLinkViewController.PrefillStrategy = .none

    private let authorizationController: AuthorizationController
    private let credentialsController: CredentialsController
    private let providerController: ProviderController

    private weak var credentialsViewController: CredentialsFormViewController?

    private lazy var addCredentialsSession = AddCredentialsSession(providerController: self.providerController, credentialsController: self.credentialsController, authorizationController: self.authorizationController, tinkLinkTracker: tinkLinkTracker, presenter: self.presenter)

    private let action: Action
    private let completion: (Result<(Credentials, AuthorizationCode?), TinkLinkError>) -> Void
    private weak var presenter: CredentialsCoordinatorPresenting?
    private weak var delegate: CredentialsCoordinatorDelegate?
    private let clientDescription: ClientDescription
    private let tinkLinkTracker: TinkLinkTracker

    private var fetchedCredentials: Credentials?

    private var callCompletionOnError: Bool {
        switch action {
        case .authenticate, .refresh:
            return true
        case .update, .create:
            return false
        }
    }

    init(authorizationController: AuthorizationController, credentialsController: CredentialsController, providerController: ProviderController, presenter: CredentialsCoordinatorPresenting, delegate: CredentialsCoordinatorDelegate, clientDescription: ClientDescription, action: Action, tinkLinkTracker: TinkLinkTracker, completion: @escaping (Result<(Credentials, AuthorizationCode?), TinkLinkError>) -> Void) {
        self.authorizationController = authorizationController
        self.credentialsController = credentialsController
        self.providerController = providerController
        self.action = action
        self.completion = completion
        self.presenter = presenter
        self.delegate = delegate
        self.clientDescription = clientDescription
        self.tinkLinkTracker = tinkLinkTracker
    }

    func start() {
        switch action {
        case .create(provider: let provider, _):
            let credentialsViewController = CredentialsFormViewController(provider: provider, credentialsController: credentialsController, clientName: clientDescription.name, isAggregator: clientDescription.isAggregator, isVerified: clientDescription.isVerified, tinkLinkTracker: tinkLinkTracker)
            credentialsViewController.delegate = self
            credentialsViewController.prefillStrategy = prefillStrategy
            credentialsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            self.credentialsViewController = credentialsViewController
            presenter?.show(credentialsViewController)
            tinkLinkTracker.providerID = provider.id.value
            tinkLinkTracker.track(screen: .submitCredentials)

        case .authenticate(credentialsID: let id):
            tinkLinkTracker.credentialsID = id.value
            fetchCredentials(with: id) { credentials in
                self.fetchedCredentials = credentials
                self.addCredentialsSession.authenticateCredentials(credentials: credentials) { result in
                    self.handleCompletion(for: result.map { ($0, nil) })
                }
            }
            presenter?.showLoadingIndicator(text: nil, onCancel: nil)

        case .refresh(credentialsID: let id, let forceAuthenticate):
            tinkLinkTracker.credentialsID = id.value
            fetchCredentials(with: id) { credentials in
                self.fetchedCredentials = credentials
                self.addCredentialsSession.refreshCredentials(credentials: credentials, forceAuthenticate: forceAuthenticate) { result in
                    self.handleCompletion(for: result.map { ($0, nil) })
                }
            }
            presenter?.showLoadingIndicator(text: nil, onCancel: nil)

        case .update(credentialsID: let id):
            tinkLinkTracker.credentialsID = id.value
            fetchCredentials(with: id) { credentials in
                self.fetchedCredentials = credentials
                self.fetchProvider(with: credentials.providerID) { provider in
                    let credentialsViewController = CredentialsFormViewController(credentials: credentials, provider: provider, credentialsController: self.credentialsController, clientName: self.clientDescription.name, isAggregator: self.clientDescription.isAggregator, isVerified: self.clientDescription.isVerified, tinkLinkTracker: self.tinkLinkTracker)
                    credentialsViewController.delegate = self
                    credentialsViewController.prefillStrategy = self.prefillStrategy
                    credentialsViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel))
                    self.credentialsViewController = credentialsViewController
                    self.presenter?.show(credentialsViewController)
                    self.tinkLinkTracker.providerID = credentials.providerID.value
                    self.tinkLinkTracker.track(screen: .submitCredentials)
                }
            }
            presenter?.showLoadingIndicator(text: nil, onCancel: nil)
        }
    }

    private func handleCompletion(for result: Result<(Credentials, AuthorizationCode?), Error>) {
        do {
            presenter?.hideLoadingIndicator()
            let (credentials, authorizationCode) = try result.get()
            tinkLinkTracker.credentialsID = credentials.id.value
            delegate?.didFinishCredentialsForm()
            showAddCredentialSuccess(with: credentials, authorizationCode: authorizationCode, for: action)
        } catch ThirdPartyAppAuthenticationTask.Error.cancelled {
            tinkLinkTracker.credentialsID = nil
            if callCompletionOnError {
                completion(.failure(.userCancelled))
            }
        } catch let error as ThirdPartyAppAuthenticationTask.Error {
            showDownloadPrompt(for: error)
            tinkLinkTracker.credentialsID = nil
            tinkLinkTracker.track(screen: .error)
        } catch SupplementInformationTask.Error.cancelled {
            if callCompletionOnError {
                completion(.failure(.userCancelled))
            }
        } catch TinkLinkError.userCancelled, AddCredentialsTask.Error.cancelled, UpdateCredentialsTask.Error.cancelled {
            tinkLinkTracker.credentialsID = nil
            if callCompletionOnError {
                completion(.failure(.userCancelled))
            } else if let credentialsViewController = credentialsViewController {
                presenter?.show(credentialsViewController)
            }
        } catch {
            showAlert(for: error)
            tinkLinkTracker.credentialsID = nil
            tinkLinkTracker.track(screen: .error)
        }
    }

    func showAddCredentialSuccess(with credentials: Credentials, authorizationCode: AuthorizationCode?, for: Action) {
        DispatchQueue.main.async {
            switch self.action {
            case .create(provider: let provider, _):
                let viewController = CredentialsSuccessfullyAddedViewController(companyName: provider.displayName, operation: .create) { [weak self] in
                    self?.completion(.success((credentials, authorizationCode)))
                }
                self.tinkLinkTracker.track(screen: .success)
                self.presenter?.show(viewController)
            default:
                self.fetchProvider(with: credentials.providerID) { provider in
                    let viewController = CredentialsSuccessfullyAddedViewController(companyName: provider.displayName, operation: .other) { [weak self] in
                        self?.completion(.success((credentials, authorizationCode)))
                    }
                    self.tinkLinkTracker.track(screen: .success)
                    self.presenter?.show(viewController)
                }
            }
        }
    }
}

// MARK: - Fetcher Helpers

extension CredentialsCoordinator {
    private func fetchCredentials(with id: Credentials.ID, then: @escaping (Credentials) -> Void) {
        credentialsController.credentials(id: id) { result in
            do {
                let credentials = try result.get()
                then(credentials)
            } catch {
                // TODO: This error should be improved
                self.completion(.failure(.credentialsNotFound))
            }
        }
    }

    private func fetchProvider(with id: Provider.ID, then: @escaping (Provider) -> Void) {
        providerController.fetchProvider(with: id) { result in
            do {
                let provider = try result.get()
                then(provider)
            } catch {
                // TODO: This error should be improved
                self.completion(.failure(.providerNotFound))
            }
        }
    }
}

extension CredentialsCoordinator: CredentialsFormViewControllerDelegate {
    func showScopeDescriptions() {
        let scopeList: [Scope]
        if case .create(provider: _, mode: let mode) = action, case .anonymous(let scopes) = mode {
            scopeList = scopes
        } else {
            scopeList = []
        }
        let viewController = ScopeDescriptionListViewController(authorizationController: authorizationController, scopes: scopeList)
        viewController.delegate = self
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Generic.done, style: .plain, target: self, action: #selector(closeMoreInfo))
        let navigationController = TinkNavigationController(rootViewController: viewController)
        presenter?.present(navigationController, animated: true, completion: nil)
    }

    func showWebContent(with url: URL) {
        let viewController = LegalViewController(url: url)
        presenter?.present(viewController, animated: true, completion: nil)
    }

    func submit(form: Form) {
        switch action {
        case .create(provider: let provider, mode: let mode):
            switch provider.accessType {
            case .openBanking:
                tinkLinkTracker.track(applicationEvent: .credentialsSubmitted)
            case .other:
                tinkLinkTracker.track(applicationEvent: .providerAuthenticationInitialized)
            default: break
            }
            addCredentialsSession.addCredential(provider: provider, form: form, mode: mode) { [weak self] result in
                self?.handleCompletion(for: result)
            }

        case .update(credentialsID: let id):
            guard let fetchedCredentials = fetchedCredentials else {
                fatalError()
            }
            assert(id == fetchedCredentials.id)

            addCredentialsSession.updateCredentials(credentials: fetchedCredentials, form: form) { [weak self] result in
                self?.handleCompletion(for: result.map { ($0, nil) })
            }

        case .authenticate, .refresh:
            break
        }
        tinkLinkTracker.track(interaction: .submitCredentials, screen: .submitCredentials)
    }
}

extension CredentialsCoordinator: ScopeDescriptionListViewControllerDelegate {
    func scopeDescriptionListViewController(viewController: ScopeDescriptionListViewController, error: Error) {
        presenter?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Actions

extension CredentialsCoordinator {
    @objc private func closeMoreInfo(_ sender: UIBarButtonItem) {
        presenter?.dismiss(animated: true, completion: nil)
    }

    @objc private func cancel() {
        if !credentialsController.newlyAddedFailedCredentialsID.isEmpty {
            completion(.failure(TinkLinkError.failedToAddCredentials(credentialsController.newlyAddedFailedCredentialsID)))
        } else {
            completion(.failure(TinkLinkError.userCancelled))
        }
    }
}

// MARK: - Alerts

extension CredentialsCoordinator {
    private func showDownloadPrompt(for thirdPartyAppAuthenticationError: ThirdPartyAppAuthenticationTask.Error) {
        let alertController = UIAlertController(title: thirdPartyAppAuthenticationError.errorDescription, message: thirdPartyAppAuthenticationError.failureReason, preferredStyle: .alert)

        if let appStoreURL = thirdPartyAppAuthenticationError.appStoreURL, UIApplication.shared.canOpenURL(appStoreURL), !callCompletionOnError {
            let cancelAction = UIAlertAction(title: Strings.Generic.cancel, style: .cancel)
            let downloadAction = UIAlertAction(title: Strings.ThirdPartyAppAuthentication.DownloadAlert.download, style: .default, handler: { _ in
                UIApplication.shared.open(appStoreURL)
            })
            alertController.addAction(cancelAction)
            alertController.addAction(downloadAction)
        } else {
            let okAction = UIAlertAction(title: Strings.Generic.dismiss, style: .default) { _ in
                if self.callCompletionOnError {
                    self.completion(.failure(.unableToOpenThirdPartyApp(thirdPartyAppAuthenticationError)))
                }
            }
            alertController.addAction(okAction)
        }

        presenter?.present(alertController, animated: true, completion: nil)
    }

    private func showAlert(for error: Error) {
        let title: String
        let message: String?
        if let error = error as? LocalizedError {
            title = error.errorDescription ?? Strings.Generic.error
            message = error.failureReason
        } else {
            title = Strings.Generic.error
            message = error.localizedDescription
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: Strings.Generic.ok, style: .default) { _ in
            if self.callCompletionOnError {
                self.completion(.failure(.internalError))
            }
        }
        alertController.addAction(okAction)

        presenter?.present(alertController, animated: true, completion: nil)
    }
}
