import Foundation

/// A task that manages progress of adding a beneficiary to an account.
///
/// Use `TransferContext` to create a task.
public final class AddBeneficiaryTask: Cancellable {
    // MARK: Types
    typealias CredentialsStatusPollingTask = PollingTask<Credentials.ID, Credentials>

    /// Indicates the state of a beneficiary being added.
    public enum Status {
        /// The adding beneficiary request has been sent.
        case requestSent
        /// The user needs to be authenticated.
        case authenticating
    }

    /// Represents an authentication that needs to be completed by the user.
    ///
    /// - Note: Each case have an associated task which need to be completed by the user to continue the transfer initiation process.
    public enum AuthenticationTask {
        /// Indicates that there is additional information required from the user to proceed.
        ///
        /// This can for example be an OTP sent via SMS or authetication app.
        case awaitingSupplementalInformation(SupplementInformationTask)
        /// Indicates that there is an authentication in a third party app necessary to proceed with the authentication.
        case awaitingThirdPartyAppAuthentication(ThirdPartyAppAuthenticationTask)
    }

    /// Error that the `AddBeneficiaryTask` can throw.
    public enum Error: Swift.Error {
        /// The authentication failed. The payload from the backend can be found in the associated value.
        case authenticationFailed(String)
        /// The credentials are disabled. The payload from the backend can be found in the associated value.
        case disabledCredentials(String)
        /// The credentials session was expired. The payload from the backend can be found in the associated value.
        case credentialsSessionExpired(String)
        /// The beneficiary could not be found.
        case notFound(String)
    }

    // MARK: Dependencies
    private let transferService: TransferService
    private let credentialsService: CredentialsService

    // MARK: Properties
    private let appUri: URL
    private let ownerAccountID: Account.ID
    private let ownerAccountCredentialsID: Credentials.ID
    private let name: String
    private let accountNumberType: String
    private let accountNumber: String
    private let progressHandler: (Status) -> Void
    private let authenticationHandler: (AuthenticationTask) -> Void
    private let completionHandler: (Result<Void, Swift.Error>) -> Void

    // MARK: Tasks
    private var credentialsStatusPollingTask: CredentialsStatusPollingTask?
    private var supplementInformationTask: SupplementInformationTask?
    private var thirdPartyAppAuthenticationTask: ThirdPartyAppAuthenticationTask?

    var callCanceller: Cancellable?
    private var fetchBeneficiariesCanceller: Cancellable?

    // MARK: State
    private var isCancelled = false
    private var didComplete = false

    // MARK: Initializers
    init(
        transferService: TransferService,
        credentialsService: CredentialsService,
        appUri: URL,
        ownerAccountID: Account.ID,
        ownerAccountCredentialsID: Credentials.ID,
        name: String,
        accountNumberType: String,
        accountNumber: String,
        progressHandler: @escaping (Status) -> Void,
        authenticationHandler: @escaping (AuthenticationTask) -> Void,
        completionHandler: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        self.transferService = transferService
        self.credentialsService = credentialsService
        self.appUri = appUri
        self.ownerAccountID = ownerAccountID
        self.ownerAccountCredentialsID = ownerAccountCredentialsID
        self.name = name
        self.accountNumberType = accountNumberType
        self.accountNumber = accountNumber
        self.progressHandler = progressHandler
        self.authenticationHandler = authenticationHandler
        self.completionHandler = completionHandler
    }
}

// MARK: - Task Lifecycle

extension AddBeneficiaryTask {
    func start() {
        let request = CreateBeneficiaryRequest(
            accountNumberType: accountNumberType,
            accountNumber: accountNumber,
            name: name,
            ownerAccountID: ownerAccountID,
            credentialsID: ownerAccountCredentialsID
        )

        callCanceller = transferService.addBeneficiary(request: request) { [weak self, credentialsID = ownerAccountCredentialsID] (result) in
            do {
                try result.get()
                self?.progressHandler(.requestSent)
                self?.startObservingCredentials(id: credentialsID)
            } catch {
                self?.complete(with: .failure(error))
            }
        }
    }

    /// Cancel the task.
    public func cancel() {
        callCanceller?.cancel()
        fetchBeneficiariesCanceller?.cancel()
        isCancelled = true
    }
}

// MARK: - Credentials Observing

extension AddBeneficiaryTask {
    private func startObservingCredentials(id: Credentials.ID) {
        if isCancelled { return }

        credentialsStatusPollingTask = CredentialsStatusPollingTask(
            id: id,
            initialValue: nil,
            request: credentialsService.credentials,
            predicate: { (old, new) in
                old.statusUpdated != new.statusUpdated || old.status != new.status
            },
            updateHandler: { [weak self] result in
                self?.handleUpdate(for: result)
            }
        )

        credentialsStatusPollingTask?.startPolling()
    }

    private func handleUpdate(for result: Result<Credentials, Swift.Error>) {
        if isCancelled { return }
        do {
            let credentials = try result.get()
            try handleCredentials(credentials)
        } catch {
            complete(with: .failure(error))
        }
    }

    private func handleCredentials(_ credentials: Credentials) throws {
        switch credentials.status {
        case .created:
            break
        case .authenticating:
            progressHandler(.authenticating)
        case .awaitingSupplementalInformation:
            self.credentialsStatusPollingTask?.stopPolling()
            let task = makeSupplementInformationTask(for: credentials) { [weak self] result in
                do {
                    try result.get()
                    self?.credentialsStatusPollingTask?.startPolling()
                } catch {
                    self?.complete(with: .failure(error))
                }
                self?.supplementInformationTask = nil
            }
            supplementInformationTask = task
            authenticationHandler(.awaitingSupplementalInformation(task))
        case .awaitingThirdPartyAppAuthentication, .awaitingMobileBankIDAuthentication:
            self.credentialsStatusPollingTask?.stopPolling()
            let task = try makeThirdPartyAppAuthenticationTask(for: credentials) { [weak self] result in
                do {
                    try result.get()
                    self?.credentialsStatusPollingTask?.startPolling()
                } catch {
                    self?.complete(with: .failure(error))
                }
                self?.thirdPartyAppAuthenticationTask = nil
            }
            thirdPartyAppAuthenticationTask = task
            authenticationHandler(.awaitingThirdPartyAppAuthentication(task))
        case .updating:
            complete(with: .success(credentials))
        case .updated:
            complete(with: .success(credentials))
        case .permanentError:
            throw Error.authenticationFailed(credentials.statusPayload)
        case .temporaryError:
            throw Error.authenticationFailed(credentials.statusPayload)
        case .authenticationError:
            var payload: String
            // Noticed that the frontend could get an unauthenticated error with an empty payload while trying to add the same third-party authentication credentials twice.
            // Happens if the frontend makes the update credentials request before the backend stops waiting for the previously added credentials to finish authenticating or time-out.
            if credentials.kind == .mobileBankID || credentials.kind == .thirdPartyAuthentication {
                payload = credentials.statusPayload.isEmpty ? "Please try again later" : credentials.statusPayload
            } else {
                payload = credentials.statusPayload
            }
            throw Error.authenticationFailed(payload)
        case .disabled:
            throw Error.disabledCredentials(credentials.statusPayload)
        case .sessionExpired:
            throw Error.credentialsSessionExpired(credentials.statusPayload)
        case .unknown:
            assertionFailure("Unknown credentials status!")
        }
    }
}

// MARK: - Awaiting Authentication Helpers

extension AddBeneficiaryTask {
    private func makeSupplementInformationTask(for credentials: Credentials, completion: @escaping (Result<Void, Swift.Error>) -> Void) -> SupplementInformationTask {
        return SupplementInformationTask(
            credentialsService: credentialsService,
            credentials: credentials,
            completionHandler: completion
        )
    }

    private func makeThirdPartyAppAuthenticationTask(for credentials: Credentials, completion: @escaping (Result<Void, Swift.Error>) -> Void) throws -> ThirdPartyAppAuthenticationTask {
        guard let thirdPartyAppAuthentication = credentials.thirdPartyAppAuthentication else {
            throw Error.authenticationFailed("Missing third party app authentication deeplink URL.")
        }

        return ThirdPartyAppAuthenticationTask(
            credentials: credentials,
            thirdPartyAppAuthentication: thirdPartyAppAuthentication,
            appUri: appUri,
            credentialsService: credentialsService,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false,
            completionHandler: completion
        )
    }
}

// MARK: - Task Completion

extension AddBeneficiaryTask {
    private func complete(with result: Result<Credentials, Swift.Error>) {
        if didComplete { return }
        defer { didComplete = true }

        credentialsStatusPollingTask?.stopPolling()
        do {
            _ = try result.get()
            completionHandler(.success)
        } catch {
            completionHandler(.failure(error))
        }
    }
}
