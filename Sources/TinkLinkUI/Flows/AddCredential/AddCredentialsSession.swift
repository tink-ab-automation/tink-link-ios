import UIKit
import TinkLink

final class AddCredentialsSession {
    weak var presenter: CredentialsCoordinatorPresenting?

    private let providerController: ProviderController
    private let credentialsController: CredentialsController
    private let authorizationController: AuthorizationController
    private var addCredentialsMode: CredentialsCoordinator.AddCredentialsMode = .user
    private let tinkLinkTracker: TinkLinkTracker

    private var task: Cancellable?
    private var supplementInfoTask: SupplementInformationTask?

    private var statusViewController: AddCredentialsStatusViewController?
    private weak var qrImageViewController: QRImageViewController?
    private var statusPresentationManager = AddCredentialsStatusPresentationManager()

    private var authorizationCode: AuthorizationCode?
    private var didCallAuthorize = false
    private var shouldAuthorize: Bool {
        if case .anonymous = addCredentialsMode {
            return true
        } else {
            return false
        }
    }

    private var isPresenterShowingStatusScreen = true
    private var authorizationGroup = DispatchGroup()

    private var providerID: Provider.ID?

    init(providerController: ProviderController, credentialsController: CredentialsController, authorizationController: AuthorizationController, tinkLinkTracker: TinkLinkTracker, presenter: CredentialsCoordinatorPresenting?) {
        self.presenter = presenter
        self.providerController = providerController
        self.credentialsController = credentialsController
        self.authorizationController = authorizationController
        self.tinkLinkTracker = tinkLinkTracker
    }

    deinit {
        task?.cancel()
    }

    func addCredential(provider: Provider, form: Form, mode: CredentialsCoordinator.AddCredentialsMode, onCompletion: @escaping ((Result<(Credentials, AuthorizationCode?), Error>) -> Void)) {
        let refreshableItems: RefreshableItems
        switch mode {
        case .anonymous(scopes: let scopes):
            refreshableItems = RefreshableItems.makeRefreshableItems(scopes: scopes, provider: provider)
        case .user:
            refreshableItems = .all
        }

        task = credentialsController.addCredentials(
            provider,
            form: form,
            refreshableItems: refreshableItems,
            progressHandler: { [weak self] status in
                DispatchQueue.main.async {
                    self?.handleAddCredentialStatus(status) {
                        [weak self] error in
                        DispatchQueue.main.async {
                            self?.hideProgress(animated: true) {
                                onCompletion(.failure(error))
                            }
                            self?.task?.cancel()
                            self?.task = nil
                        }
                    }
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleCompletion(result, onCompletion: onCompletion)
                }
            }
        )
        isPresenterShowingStatusScreen = false
        providerID = provider.id
        addCredentialsMode = mode

        DispatchQueue.main.async {
            self.showProgress(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func updateCredentials(credentials: Credentials, form: Form, completion: @escaping (Result<Credentials, Error>) -> Void) {
        task = credentialsController.update(credentials, form: form, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        isPresenterShowingStatusScreen = false
        providerID = credentials.providerID

        DispatchQueue.main.async {
            self.showProgress(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func refreshCredentials(credentials: Credentials, forceAuthenticate: Bool, completion: @escaping (Result<Credentials, Error>) -> Void) {
        var authenticate: Bool {
            if let sessionExpiryDate = credentials.sessionExpiryDate, sessionExpiryDate <= Date() {
                return true
            }
            return forceAuthenticate
        }

        task = credentialsController.refresh(credentials, authenticate: authenticate, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        providerID = credentials.providerID

        DispatchQueue.main.async {
            self.showProgress(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func authenticateCredentials(credentials: Credentials, completion: @escaping (Result<Credentials, Error>) -> Void) {
        task = credentialsController.authenticate(credentials, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        providerID = credentials.providerID

        DispatchQueue.main.async {
            self.showProgress(status: Strings.CredentialsStatus.authorizing)
        }
    }

    private func handleAddCredentialStatus(_ status: AddCredentialsTask.Status, onError: @escaping (Error) -> Void) {
        switch status {
        case .created, .authenticating:
            break
        case .awaitingSupplementalInformation(let supplementInformationTask):
            tinkLinkTracker.credentialsID = supplementInformationTask.credentials.id.value
            showSupplementalInformation(for: supplementInformationTask)
        case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthenticationTask):
            handleThirdPartyAppAuthentication(task: thirdPartyAppAuthenticationTask)
        case .updating:
            let status: String
            if let providerID = providerID, let bankName = providerController.provider(providerID: providerID)?.displayName {
                let statusFormatText = Strings.CredentialsStatus.updating
                status = String(format: statusFormatText, bankName)
            } else {
                status = Strings.CredentialsStatus.updatingFallback
            }
            showUpdating(status: status)
            authorizeIfNeeded(onError: onError)
        }
    }

    private func handleUpdateTaskStatus(_ status: UpdateCredentialsTask.Status) {
        switch status {
        case .authenticating:
            break
        case .awaitingSupplementalInformation(let supplementInformationTask):
            showSupplementalInformation(for: supplementInformationTask)
        case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthenticationTask):
            handleThirdPartyAppAuthentication(task: thirdPartyAppAuthenticationTask)
        case .updating:
            let status: String
            if let providerID = providerID, let bankName = providerController.provider(providerID: providerID)?.displayName {
                let statusFormatText = Strings.CredentialsStatus.updating
                status = String(format: statusFormatText, bankName)
            } else {
                status = Strings.CredentialsStatus.updatingFallback
            }
            showUpdating(status: status)
        }
    }

    private func handleThirdPartyAppAuthentication(task: ThirdPartyAppAuthenticationTask) {
        task.handle { [weak self] result in
            switch result {
            case .qrImage(let image):
                DispatchQueue.main.async {
                    self?.showQRCodeView(qrImage: image)
                }
            case .awaitAuthenticationOnAnotherDevice:
                DispatchQueue.main.async {
                    self?.showProgress(status: Strings.CredentialsStatus.waitingForAuthenticationOnAnotherDevice)
                }
            }
        }
    }

    private func handleCompletion(_ result: Result<Credentials, Error>, onCompletion: @escaping ((Result<(Credentials, AuthorizationCode?), Error>) -> Void)) {
        do {
            let credentials = try result.get()
            credentialsController.newlyAddedFailedCredentialsID[credentials.id] = nil
            authorizeIfNeeded(onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.hideProgress(animated: true) {
                        onCompletion(.failure(error))
                    }
                }
            })
            authorizationGroup.notify(queue: .main) { [weak self] in
                self?.hideProgress(animated: true) {
                    onCompletion(.success((credentials, self?.authorizationCode)))
                }
            }
        } catch {
            let addCredentialsTask = task as? AddCredentialsTask
            if let credentialsID = addCredentialsTask?.credentials?.id {
                credentialsController.newlyAddedFailedCredentialsID[credentialsID] = error
            }
            hideProgress(animated: true) {
                onCompletion(.failure(error))
            }
        }
        task = nil
    }

    private func authorizeIfNeeded(onError: @escaping (Error) -> Void) {
        if didCallAuthorize || !shouldAuthorize { return }

        guard case .anonymous(let scopes) = addCredentialsMode else { return }

        didCallAuthorize = true
        authorizationGroup.enter()
        authorizationController.authorize(scopes: scopes) { [weak self] result in
            do {
                let authorizationCode = try result.get()
                self?.authorizationCode = authorizationCode
            } catch {
                self?.didCallAuthorize = false
                onError(AddCredentialsTask.Error.temporaryFailure("A temporary error has occurred"))
            }
            self?.authorizationGroup.leave()
        }
    }

    private func cancel() {
        hideProgress(animated: true)
        task?.cancel()
    }
}

extension AddCredentialsSession {
    private func showSupplementalInformation(for supplementInformationTask: SupplementInformationTask) {
        supplementInfoTask = supplementInformationTask
        hideProgress(animated: true) {
            let supplementalInformationViewController = SupplementalInformationViewController(supplementInformationTask: supplementInformationTask)
            supplementalInformationViewController.delegate = self
            let navigationController = TinkNavigationController(rootViewController: supplementalInformationViewController)
            self.presenter?.present(navigationController, animated: true, completion: nil)
            self.tinkLinkTracker.track(screen: .supplementalInformation)
        }
    }

    private func showProgress(status: String) {
        hideQRCodeViewIfNeeded(animated: true) {
            if self.isPresenterShowingStatusScreen {
                self.presenter?.showLoadingIndicator(text: status) { [weak self] in
                    self?.cancel()
                }
                return
            }

            if let statusViewController = self.statusViewController {
                if statusViewController.presentingViewController == nil {
                    self.presenter?.present(statusViewController, animated: true, completion: nil)
                }
            } else {
                let statusViewController = AddCredentialsStatusViewController()
                statusViewController.delegate = self
                statusViewController.modalTransitionStyle = .crossDissolve
                statusViewController.modalPresentationStyle = .custom
                statusViewController.transitioningDelegate = self.statusPresentationManager
                self.presenter?.present(statusViewController, animated: true, completion: nil)
                self.statusViewController = statusViewController
            }

            self.statusViewController?.status = status
        }
    }

    private func showUpdating(status: String) {
        hideQRCodeViewIfNeeded(animated: true) {
            self.hideProgress(animated: true) {
                let loadingViewController = LoadingViewController()
                loadingViewController.update(status, onCancel: { [weak self] in
                    self?.cancel()
                })
                self.presenter?.show(loadingViewController)
            }
        }
    }

    private func hideProgress(animated: Bool, completion: (() -> Void)? = nil) {
        hideQRCodeViewIfNeeded(animated: animated)
        guard statusViewController != nil, statusViewController?.presentingViewController != nil else {
            completion?()
            return
        }
        statusViewController = nil
        presenter?.dismiss(animated: animated, completion: completion)
    }

    private func showQRCodeView(qrImage: UIImage) {
        hideProgress(animated: true) {
            let qrImageViewController = QRImageViewController(qrImage: qrImage)
            self.qrImageViewController = qrImageViewController
            qrImageViewController.delegate = self
            self.presenter?.present(TinkNavigationController(rootViewController: qrImageViewController), animated: true, completion: nil)
        }
    }

    private func hideQRCodeViewIfNeeded(animated: Bool = false, completion: (() -> Void)? = nil) {
        guard qrImageViewController != nil else {
            completion?()
            return
        }
        presenter?.dismiss(animated: animated, completion: completion)
    }
}

// MARK: - AddCredentialsStatusViewControllerDelegate

extension AddCredentialsSession: AddCredentialsStatusViewControllerDelegate {
    func addCredentialsStatusViewControllerDidCancel(_ viewController: AddCredentialsStatusViewController) {
        cancel()
    }
}

// MARK: - SupplementalInformationViewControllerDelegate

extension AddCredentialsSession: SupplementalInformationViewControllerDelegate {
    func supplementalInformationViewControllerDidCancel(_ viewController: SupplementalInformationViewController) {
        presenter?.dismiss(animated: true) {
            self.supplementInfoTask?.cancel()
            self.showProgress(status: Strings.CredentialsStatus.cancelling)
        }
    }

    func supplementalInformationViewController(_ viewController: SupplementalInformationViewController, didPressSubmitWithForm form: Form) {
        presenter?.dismiss(animated: true) {
            self.supplementInfoTask?.submit(form)
            self.showProgress(status: Strings.CredentialsStatus.sending)
        }
    }
}

extension AddCredentialsSession: QRImageViewControllerDelegate {
    func qrImageViewControllerDidCancel(_ viewController: QRImageViewController) {
        presenter?.dismiss(animated: true) {
            self.task?.cancel()
        }
    }
}
