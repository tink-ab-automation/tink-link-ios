import Foundation

/// A task that manages progress of adding a credential.
///
/// Use `CredentialsContext` to create a task.
public final class AddCredentialsTask: Identifiable, Cancellable {
    typealias CredentialsStatusPollingTask = PollingTask<Credentials.ID, Credentials>

    /// Indicates the state of a credentials being added.
    public enum Status {
        /// Initial status
        case created(Credentials.ID)

        /// The user needs to be authenticated. The payload from the backend can be found in the message property.
        case authenticating(String?)

        /// User has been successfully authenticated, now fetching data.
        case updating
    }

    /// Error that the `AddCredentialsTask` can throw.
    public typealias Error = TinkLinkError

    var pollingStrategy: PollingStrategy = .linear(1, maxInterval: 10)

    private var credentialsStatusPollingTask: CredentialsStatusPollingTask?
    private var supplementInformationTask: SupplementInformationTask?
    private var thirdPartyAuthenticationTask: ThirdPartyAppAuthenticationTask?
    private let authenticationHandler: AuthenticationTaskHandler
    /// The credentials that are being added.
    public private(set) var credentials: Credentials?

    // MARK: - Evaluating Completion

    /// Cases to evaluate when credentials status changes.
    ///
    /// Use with `CredentialsContext.addCredentials(for:form:completionPredicate:progressHandler:completion:)` to set when add credentials task should call completion handler if successful.
    public struct CompletionPredicate {
        /// Determines when the add credentials task is considered done.
        public struct SuccessPredicate: Equatable, CustomStringConvertible {
            private enum Value {
                case updating
                case updated
            }

            private let value: Value

            public var description: String {
                return "AddCredentialsTask.CompletionPredicate.SuccessPredicate.\(value)"
            }

            /// A predicate that indicates the credentials' status is `updating`.
            public static let updating = Self(value: .updating)
            /// A predicate that indicates the credentials' status is `updated`.
            public static let updated = Self(value: .updated)
        }

        /// Determines when the add credentials task is considered done.
        public let successPredicate: SuccessPredicate

        /// Determines if the add credentials task should fail if a third party app could not be opened for authentication.
        public let shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool

        /// Determines when the add credentials task is considered done or should fail.
        /// - Parameters:
        ///   - successPredicate: Predicate determining when the add credentials task should succeed.
        ///   - shouldFailOnThirdPartyAppAuthenticationDownloadRequired: A Boolean value determining if the task should fail when a third party app could not be opened.
        public init(successPredicate: SuccessPredicate, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool) {
            self.successPredicate = successPredicate
            self.shouldFailOnThirdPartyAppAuthenticationDownloadRequired = shouldFailOnThirdPartyAppAuthenticationDownloadRequired
        }
    }

    /// Predicate for when credentials task is completed.
    ///
    /// Task will execute it's completion handler if the credentials' status changes to match this predicate.
    public let completionPredicate: CompletionPredicate

    private let credentialsService: CredentialsService
    private let appUri: URL
    let progressHandler: (Status) -> Void
    let completion: (Result<Credentials, Swift.Error>) -> Void

    var callCanceller: Cancellable?
    private var isCancelled = false

    init(credentialsService: CredentialsService, completionPredicate: CompletionPredicate, appUri: URL, progressHandler: @escaping (Status) -> Void, authenticationHandler: @escaping AuthenticationTaskHandler, completion: @escaping (Result<Credentials, Swift.Error>) -> Void) {
        self.credentialsService = credentialsService
        self.completionPredicate = completionPredicate
        self.appUri = appUri
        self.progressHandler = progressHandler
        self.authenticationHandler = authenticationHandler
        self.completion = completion
    }

    func startObserving(_ credentials: Credentials) {
        self.credentials = credentials
        if isCancelled { return }

        handleUpdate(for: .success(credentials))
        credentialsStatusPollingTask = CredentialsStatusPollingTask(
            id: credentials.id,
            initialValue: credentials,
            request: credentialsService.credentials,
            predicate: { (old, new) -> Bool in
                old.statusUpdated != new.statusUpdated || old.status != new.status
            }
        ) { [weak self] result in
            self?.handleUpdate(for: result)
        }
        credentialsStatusPollingTask?.pollingStrategy = pollingStrategy
        credentialsStatusPollingTask?.startPolling()
    }

    // MARK: - Controlling the Task

    /// Cancel the task.
    public func cancel() {
        isCancelled = true
        credentialsStatusPollingTask?.stopPolling()
        if let canceller = callCanceller {
            canceller.cancel()
        } else if let task = thirdPartyAuthenticationTask {
            task.cancel()
        } else {
            complete(with: .failure(Error(code: .cancelled)))
        }
    }

    private func complete(with result: Result<Credentials, Swift.Error>) {
        credentialsStatusPollingTask?.stopPolling()
        completion(result)
    }

    private func handleUpdate(for result: Result<Credentials, Swift.Error>) {
        if isCancelled { return }
        do {
            let credentials = try result.get()
            switch credentials.status {
            case .created:
                progressHandler(.created(credentials.id))
            case .authenticating:
                progressHandler(.authenticating(credentials.statusPayload))
            case .awaitingSupplementalInformation:
                credentialsStatusPollingTask?.stopPolling()
                let supplementInformationTask = SupplementInformationTask(credentialsService: credentialsService, credentials: credentials) { [weak self] result in
                    guard let self = self else { return }
                    do {
                        try result.get()
                        self.credentialsStatusPollingTask?.startPolling()
                    } catch SupplementInformationTask.Error.cancelled {
                        self.complete(with: .failure(Error(code: .cancelled)))
                    } catch {
                        self.complete(with: .failure(error))
                    }
                    self.supplementInformationTask = nil
                }
                self.supplementInformationTask = supplementInformationTask
                authenticationHandler(.awaitingSupplementalInformation(supplementInformationTask))
            case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthentication), .awaitingMobileBankIDAuthentication(let thirdPartyAppAuthentication):
                credentialsStatusPollingTask?.stopPolling()

                let task = ThirdPartyAppAuthenticationTask(credentials: credentials, thirdPartyAppAuthentication: thirdPartyAppAuthentication, appUri: appUri, credentialsService: credentialsService, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: completionPredicate.shouldFailOnThirdPartyAppAuthenticationDownloadRequired) { [weak self] result in
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
                if completionPredicate.successPredicate == .updating {
                    complete(with: .success(credentials))
                } else {
                    progressHandler(.updating)
                }
            case .updated:
                if completionPredicate.successPredicate == .updated {
                    complete(with: .success(credentials))
                }
            case .permanentError:
                throw Error.permanentCredentialsFailure(credentials.statusPayload)
            case .temporaryError:
                throw Error.temporaryCredentialsFailure(credentials.statusPayload)
            case .authenticationError:
                throw Error.credentialsAuthenticationFailed(credentials.statusPayload)
            case .deleted:
                assertionFailure("credentials shouldn't be disabled during creation.")
                throw Error.credentialsDeleted(credentials.statusPayload)
            case .sessionExpired:
                assertionFailure("Credential's session shouldn't expire during creation.")
                throw Error.credentialsSessionExpired(credentials.statusPayload)
            case .unknown:
                assertionFailure("Unknown credentials status!")
            @unknown default:
                assertionFailure("Unknown credentials status!")
            }
        } catch ServiceError.cancelled {
            complete(with: .failure(Error(code: .cancelled)))
        } catch {
            complete(with: .failure(error))
        }
    }
}
