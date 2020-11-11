import Foundation

/// A task that manages the authentication and status of a transfer.
///
/// Use `TransferContext` to create this task.
public final class InitiateTransferTask: Cancellable {
    typealias TransferStatusPollingTask = PollingTask<Transfer.ID, SignableOperation>
    typealias CredentialsStatusPollingTask = PollingTask<Credentials.ID, Credentials>

    /// Indicates the status of a transfer initiation.
    public enum Status {
        /// The transfer request has been created.
        case created(Transfer.ID)
        /// The user needs to be authenticated.
        ///
        /// The payload from the backend can be found in the associated value.
        case authenticating(String?)
        /// The credentials are updating.
        case updating
        /// User has been successfully authenticated, the transfer initiation is now being executed.
        case executing(status: String)
    }

    /// Represents an authentication that needs to be completed by the user.
    ///
    /// - Note: Each case have an associated task which need to be completed by the user to continue the transfer initiation process.
    public typealias AuthenticationTask = TinkLink.AuthenticationTask

    /// Error that the `InitiateTransferTask` can throw.
    public struct Error: Swift.Error {
        public struct Code: Hashable, RawRepresentable {
            public let rawValue: Int

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }

            public static let authenticationFailed = Self(rawValue: 1)
            public static let credentialsDeleted = Self(rawValue: 2)
            public static let credentialsSessionExpired = Self(rawValue: 3)
            public static let cancelled = Self(rawValue: 4)
            public static let failed = Self(rawValue: 5)
        }

        public var code: Code
        public var message: String?

        /// The authentication failed.
        ///
        /// The payload from the backend can be found in the associated value.
        public static let authenticationFailed: Code = .authenticationFailed
        /// The credentials are deleted.
        ///
        /// The payload from the backend can be found in the associated value.
        public static let credentialsDeleted: Code = .credentialsDeleted
        /// The credentials session was expired.
        ///
        /// The payload from the backend can be found in the associated value.
        public static let credentialsSessionExpired: Code = .credentialsSessionExpired
        /// The transfer was cancelled.
        ///
        /// The payload from the backend can be found in the associated value.
        public static let cancelled: Code = .cancelled
        /// The transfer failed.
        ///
        /// The payload from the backend can be found in the associated value.
        public static let failed: Code = .failed

        static func authenticationFailed(_ message: String?) -> Self {
            .init(code: .authenticationFailed, message: message)
        }
        static func credentialsDeleted(_ message: String?) -> Self {
            .init(code: .credentialsDeleted, message: message)
        }
        static func credentialsSessionExpired(_ message: String?) -> Self {
            .init(code: .credentialsSessionExpired, message: message)
        }
        static func cancelled(_ message: String?) -> Self {
            .init(code: .cancelled, message: message)
        }
        static func failed(_ message: String?) -> Self {
            .init(code: .failed, message: message)
        }
    }

    /// Indicates the result of transfer initiation.
    public struct Receipt {
        /// Transfer ID
        public let id: Transfer.ID
        /// Receipt message
        public let message: String?
    }

    /// Determines how the task handles the case when a user doesn't have the required authentication app installed.
    public let shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool

    var retryInterval: TimeInterval = 1.0

    private(set) var signableOperation: SignableOperation?

    var canceller: Cancellable?

    private let transferService: TransferService
    private let credentialsService: CredentialsService
    private let appUri: URL
    private let progressHandler: (Status) -> Void
    private let authenticationHandler: AuthenticationTaskHandler
    private let completionHandler: (Result<Receipt, Swift.Error>) -> Void

    private var transferStatusPollingTask: TransferStatusPollingTask?
    private var credentialsStatusPollingTask: CredentialsStatusPollingTask?
    private var thirdPartyAuthenticationTask: ThirdPartyAppAuthenticationTask?
    private var isCancelled = false

    init(transferService: TransferService, credentialsService: CredentialsService, appUri: URL, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool, progressHandler: @escaping (Status) -> Void, authenticationHandler: @escaping AuthenticationTaskHandler, completionHandler: @escaping (Result<Receipt, Swift.Error>) -> Void) {
        self.transferService = transferService
        self.credentialsService = credentialsService
        self.shouldFailOnThirdPartyAppAuthenticationDownloadRequired = shouldFailOnThirdPartyAppAuthenticationDownloadRequired
        self.appUri = appUri
        self.progressHandler = progressHandler
        self.authenticationHandler = authenticationHandler
        self.completionHandler = completionHandler
    }

    func startObserving(_ signableOperation: SignableOperation) {
        guard let transferID = signableOperation.transferID else {
            complete(with: .failure(Error.failed("Failed to get transfer ID.")))
            return
        }

        self.signableOperation = signableOperation
        if isCancelled { return }

        handleUpdate(for: .success(signableOperation))
        transferStatusPollingTask = TransferStatusPollingTask(
            id: transferID,
            initialValue: signableOperation,
            request: transferService.transferStatus,
            predicate: { (old, new) -> Bool in
                old.updated != new.updated || old.status != new.status
            }
        ) { [weak self] result in
            self?.handleUpdate(for: result)
        }

        transferStatusPollingTask?.retryInterval = retryInterval
        transferStatusPollingTask?.startPolling()
    }

    private func handleUpdate(for result: Result<SignableOperation, Swift.Error>) {
        if isCancelled { return }
        do {
            let signableOperation = try result.get()
            switch signableOperation.status {
            case .created:
                guard let transferID = signableOperation.transferID else {
                    throw Error.failed("Failed to get transfer ID.")
                }
                progressHandler(.created(transferID))
            case .awaitingCredentials, .awaitingThirdPartyAppAuthentication:
                transferStatusPollingTask?.stopPolling()
                if credentialsStatusPollingTask == nil {
                    guard let credentialsID = signableOperation.credentialsID else {
                        throw Error.failed("Failed to get credentials ID.")
                    }
                    credentialsStatusPollingTask = CredentialsStatusPollingTask(
                        id: credentialsID,
                        initialValue: nil,
                        request: credentialsService.credentials,
                        predicate: { (old, new) -> Bool in
                            guard let oldStatusUpdated = old.statusUpdated else {
                                return new.statusUpdated != nil || old.status != new.status
                            }

                            guard let newStatusUpdated = new.statusUpdated else {
                                return old.status != new.status
                            }

                            return oldStatusUpdated < newStatusUpdated || old.status != new.status
                        }
                    ) { [weak self] result in
                        self?.handleUpdate(for: result)
                    }
                }
                credentialsStatusPollingTask?.retryInterval = retryInterval
                credentialsStatusPollingTask?.startPolling()
            case .executing:
                progressHandler(.executing(status: signableOperation.statusMessage ?? ""))
            case .executed:
                complete(with: result)
            case .cancelled:
                throw Error.cancelled(signableOperation.statusMessage)
            case .failed:
                throw Error.failed(signableOperation.statusMessage)
            case .unknown:
                assertionFailure("Unknown credentials status.")
            @unknown default:
                assertionFailure("Unknown credentials status.")
            }
        } catch {
            complete(with: .failure(error))
        }
    }

    private func handleUpdate(for result: Result<Credentials, Swift.Error>) {
        if isCancelled { return }
        do {
            let credentials = try result.get()
            switch credentials.status {
            case .created: break
            case .authenticating:
                progressHandler(.authenticating(credentials.statusPayload))
            case .awaitingSupplementalInformation:
                credentialsStatusPollingTask?.stopPolling()
                let supplementInformationTask = SupplementInformationTask(credentialsService: credentialsService, credentials: credentials) { [weak self] result in
                    guard let self = self else { return }
                    do {
                        try result.get()
                        self.credentialsStatusPollingTask?.startPolling()
                    } catch {
                        self.complete(with: .failure(error))
                    }
                }
                authenticationHandler(.awaitingSupplementalInformation(supplementInformationTask))
            case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthentication), .awaitingMobileBankIDAuthentication(let thirdPartyAppAuthentication):
                credentialsStatusPollingTask?.stopPolling()

                let task = ThirdPartyAppAuthenticationTask(credentials: credentials, thirdPartyAppAuthentication: thirdPartyAppAuthentication, appUri: appUri, credentialsService: credentialsService, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired) { [weak self] result in
                    guard let self = self else { return }
                    do {
                        try result.get()
                        self.credentialsStatusPollingTask?.startPolling()
                    } catch {
                        self.complete(with: .failure(error))
                    }
                    self.thirdPartyAuthenticationTask = nil
                }
                thirdPartyAuthenticationTask = task
                authenticationHandler(.awaitingThirdPartyAppAuthentication(task))
            case .updating:
                // Need to keep polling here, updated is the state when the authentication is done.
                progressHandler(.updating)
            case .updated:
                // Stops polling when the credentials status is updating
                credentialsStatusPollingTask?.stopPolling()
                transferStatusPollingTask?.startPolling()
            case .permanentError:
                throw Error.failed(credentials.statusPayload)
            case .temporaryError:
                throw Error.failed(credentials.statusPayload)
            case .authenticationError:
                throw Error.authenticationFailed(credentials.statusPayload)
            case .deleted:
                throw Error.credentialsDeleted(credentials.statusPayload)
            case .sessionExpired:
                throw Error.credentialsSessionExpired(credentials.statusPayload)
            case .unknown:
                assertionFailure("Unknown credentials status!")
            @unknown default:
                assertionFailure("Unknown credentials status!")
            }
        } catch {
            complete(with: .failure(error))
        }
    }

    private func complete(with result: Result<SignableOperation, Swift.Error>) {
        transferStatusPollingTask?.stopPolling()
        credentialsStatusPollingTask?.stopPolling()
        do {
            let signableOperation = try result.get()
            guard let transferID = signableOperation.transferID else {
                completionHandler(.failure(Error.failed("Failed to get transfer ID.")))
                return
            }

            let response = Receipt(id: transferID, message: signableOperation.statusMessage)
            completionHandler(.success(response))
        } catch {
            completionHandler(.failure(error))
        }
    }

    /// Cancel the task.
    public func cancel() {
        isCancelled = true
        transferStatusPollingTask?.stopPolling()
        credentialsStatusPollingTask?.stopPolling()
        canceller?.cancel()
    }
}
