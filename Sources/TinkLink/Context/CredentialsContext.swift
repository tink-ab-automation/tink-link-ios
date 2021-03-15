import Foundation

/// An object that you use to list, add or modify a user's `Credentials`.
public final class CredentialsContext {
    var pollingStrategy: PollingStrategy = .linear(1, maxInterval: 10)

    private let appURI: URL
    private let callbackURI: URL?
    private let service: CredentialsService
    private var credentialThirdPartyCallbackObserver: Any?
    private var thirdPartyCallbackCanceller: RetryCancellable?

    private var newlyAddedCredentials: [Provider.Name: Credentials] = [:]

    private var cancellables: [UUID: Cancellable] = [:]

    private let configurationRegistrationUUID: UUID

    // MARK: - Creating a Credentials Context

    /// Creates a new CredentialsContext for the given Tink instance.
    ///
    /// - Parameter tink: The `Tink` instance to use. Will use the shared instance if nothing is provided.
    public convenience init(tink: Tink = .shared) {
        let service = tink.services.credentialsService
        self.init(tink: tink, credentialsService: service)
    }

    init(tink: Tink, credentialsService: CredentialsService) {
        precondition(tink.configuration.appURI != nil, "Configure Tink by calling `Tink.configure(with:)` with a `appURI` configured.")
        self.appURI = tink.configuration.appURI!
        self.callbackURI = tink.configuration.callbackURI
        self.service = credentialsService
        self.configurationRegistrationUUID = Tink.registerConfiguration(tink.configuration)
    }

    deinit {
        Tink.deregisterConfiguration(for: configurationRegistrationUUID)
    }

    // MARK: - Adding Credentials

    /// Adds credentials to the user.
    ///
    /// Required scopes:
    /// - credentials:write
    ///
    /// You need to handle potential authentication requests with `authenticationHandler` to successfully add a credentials for some providers.
    ///
    ///     let addCredentialsTask = credentialsContext.add(forProviderWithName: providerName, fields: fields, authenticationHandler: { authentication in
    ///         switch authentication {
    ///         case .awaitingSupplementalInformation(let supplementInformationTask):
    ///             <#Present form for supplemental information task#>
    ///         case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthentication):
    ///             <#Open third party app deep link URL#>
    ///         }
    ///     }, completion: { result in
    ///         <#Handle result#>
    ///     })
    ///
    /// - Parameters:
    ///   - providerName: The provider (financial institution) that you want to create a credentials for.
    ///   - fields: A dictionary of filled in fields found on the Provider to which the credentials will be created for. Can contain data such as username and password.
    ///   - refreshableItems: The data types to aggregate from the provider. Defaults to all types.
    ///   - completionPredicate: Predicate for when credentials task should complete.
    ///   - authenticationHandler: The block that will execute when the credentials needs some sort of authentication from the end user.
    ///   - task: The authentication task that needs to be handled.
    ///   - progressHandler: The block to execute with progress information about the credential's status.
    ///   - status: Indicates the state of a credentials being added.
    ///   - completion: The block to execute when the credentials has been added successfully or if it failed.
    ///   - result: Represents either a successfully added credentials or an error if adding the credentials failed.
    /// - Returns: The add credentials task.
    @discardableResult
    public func add(
        forProviderWithName providerName: Provider.Name,
        fields: [String: String],
        refreshableItems: RefreshableItems = .all,
        completionPredicate: AddCredentialsTask.CompletionPredicate = .init(successPredicate: .updated, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: true),
        authenticationHandler: @escaping (_ task: AuthenticationTask) -> Void,
        progressHandler: @escaping (_ status: AddCredentialsTask.Status) -> Void = { _ in },
        completion: @escaping (_ result: Result<Credentials, Error>) -> Void
    ) -> Cancellable {
        let id = UUID()
        let task = AddCredentialsTask(
            credentialsService: service,
            completionPredicate: completionPredicate,
            appUri: appURI,
            progressHandler: progressHandler,
            authenticationHandler: authenticationHandler,
            completion: { [weak self] result in
                completion(result.mapError(\.tinkLinkError))
                self?.cancellables[id] = nil
            }
        )

        task.pollingStrategy = pollingStrategy
        cancellables[id] = task

        if let newlyAddedCredentials = newlyAddedCredentials[providerName] {
            task.callCanceller = service.update(id: newlyAddedCredentials.id, providerName: newlyAddedCredentials.providerName, appURI: appURI, callbackURI: callbackURI, fields: fields) { [weak task] result in
                do {
                    let credentials = try result.get()
                    task?.startObserving(credentials)
                } catch {
                    completion(.failure(error.tinkLinkError))
                }
                task?.callCanceller = nil
            }
        } else {
            task.callCanceller = service.create(providerName: providerName, refreshableItems: refreshableItems, fields: fields, appURI: appURI, callbackURI: callbackURI) { [weak task, weak self] result in
                do {
                    let credential = try result.get()
                    self?.newlyAddedCredentials[providerName] = credential
                    task?.startObserving(credential)
                } catch ServiceError.alreadyExists(let message) {
                    completion(.failure(TinkLinkError.credentialsAlreadyExists(message)))
                } catch {
                    completion(.failure(error.tinkLinkError))
                }
                task?.callCanceller = nil
            }
        }
        return task
    }

    /// Adds a credentials for the user.
    ///
    /// Required scopes:
    /// - credentials:write
    ///
    /// You need to handle potential authentication requests with `authenticationHandler` to successfully add credentials for some providers.
    ///
    ///     let addCredentialsTask = credentialsContext.add(for: provider, form: form, authenticationHandler: { authentication in
    ///         switch status {
    ///         case .awaitingSupplementalInformation(let supplementInformationTask):
    ///             <#Present form for supplemental information task#>
    ///         case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthentication):
    ///             <#Open third party app deep link URL#>
    ///         default:
    ///             break
    ///         }
    ///     }, completion: { result in
    ///         <#Handle result#>
    ///     }
    ///
    /// - Parameters:
    ///   - provider: The provider (financial institution) that the credentials is connected to.
    ///   - form: This is a form with fields from the Provider to which the credentials belongs to.
    ///   - refreshableItems: The data types to aggregate from the provider. Defaults to all types.
    ///   - completionPredicate: Predicate for when credentials task should complete.
    ///   - authenticationHandler: The block that will execute when the credentials needs some sort of authentication from the end user.
    ///   - task: The authentication task that needs to be handled.
    ///   - progressHandler: The block to execute with progress information about the credential's status.
    ///   - status: Indicates the state of a credentials being added.
    ///   - completion: The block to execute when the credentials has been added successfully or if it failed.
    ///   - result: Represents either a successfully added credentials or an error if adding the credentials failed.
    /// - Returns: The add credentials task.
    @discardableResult
    public func add(
        for provider: Provider,
        form: Form,
        refreshableItems: RefreshableItems = .all,
        completionPredicate: AddCredentialsTask.CompletionPredicate = .init(successPredicate: .updated, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: true),
        authenticationHandler: @escaping (_ task: AuthenticationTask) -> Void,
        progressHandler: @escaping (_ status: AddCredentialsTask.Status) -> Void = { _ in },
        completion: @escaping (_ result: Result<Credentials, Error>) -> Void
    ) -> Cancellable {
        let refreshableItems = refreshableItems.supporting(providerCapabilities: provider.capabilities)

        return add(forProviderWithName: provider.name, fields: form.makeFields(), refreshableItems: refreshableItems, completionPredicate: completionPredicate, authenticationHandler: authenticationHandler, progressHandler: progressHandler, completion: completion)
    }

    /// Fetch a list of the current user's credentials.
    ///
    /// Required scopes:
    /// - credentials:read
    ///
    /// - Parameter completion: The block to execute when the call is completed.
    /// - Parameter result: A result that either contain a list of the user credentials or an error if the fetch failed.
    @discardableResult
    public func fetchCredentialsList(completion: @escaping (_ result: Result<[Credentials], Error>) -> Void) -> RetryCancellable? {
        return service.credentialsList { result in
            do {
                let credentials = try result.get()
                let storedCredentials = credentials.sorted(by: { $0.id.value < $1.id.value })
                completion(.success(storedCredentials))
            } catch {
                completion(.failure(error.tinkLinkError))
            }
        }
    }

    /// Fetch a credentials by ID.
    ///
    /// Required scopes:
    /// - credentials:read
    ///
    /// - Parameter id: The id of the credentials to fetch.
    /// - Parameter completion: The block to execute when the call is completed.
    /// - Parameter result: A result that either contains the credentials or an error if the fetch failed.
    @discardableResult
    public func fetchCredentials(withID id: Credentials.ID, completion: @escaping (_ result: Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        return service.credentials(id: id) { result in
            do {
                let credentials = try result.get()
                completion(.success(credentials))
            } catch {
                completion(.failure(error.tinkLinkError))
            }
        }
    }

    // MARK: - Managing Credentials

    /// Refresh the user's credentials.
    ///
    /// Required scopes:
    /// - credentials:refresh
    ///
    /// - Parameters:
    ///   - credentials: The credentials object to refresh.
    ///   - authenticate: Force an authentication before the refresh, designed for open banking credentials. Defaults to false.
    ///   - refreshableItems: The data types to aggregate from the provider. Defaults to all types.
    ///   - shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Determines how the task handles the case when a user doesn't have the required authentication app installed.
    ///   - authenticationHandler: The block that will execute when the credentials needs some sort of authentication from the end user.
    ///   - task: The authentication task that needs to be handled.
    ///   - progressHandler: The block to execute with progress information about the credential's status.
    ///   - status: Indicates the state of a credentials being refreshed.
    ///   - completion: The block to execute when the credentials has been refreshed successfully or if it failed.
    ///   - result: A result that either contains the refreshed credentials or an error if the refresh failed.
    /// - Returns: The refresh credentials task.
    @discardableResult
    public func refresh(
        _ credentials: Credentials,
        authenticate: Bool = false,
        refreshableItems: RefreshableItems = .all,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool = true,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        progressHandler: @escaping (_ status: RefreshCredentialsTask.Status) -> Void = { _ in },
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable {
        // TODO: Filter out refreshableItems not supported by provider capabilities.

        let id = UUID()

        let task = RefreshCredentialsTask(
            credentials: credentials,
            credentialsService: service,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            appUri: appURI,
            progressHandler: progressHandler,
            authenticationHandler: authenticationHandler,
            completion: { [weak self] result in
                completion(result.mapError(\.tinkLinkError))
                self?.cancellables[id] = nil
            }
        )

        cancellables[id] = task
        task.pollingStrategy = pollingStrategy

        task.callCanceller = service.refresh(id: credentials.id, authenticate: authenticate, refreshableItems: refreshableItems, optIn: false, completion: { [weak task] result in
            switch result {
            case .success:
                task?.startObserving()
            case .failure(let error):
                completion(.failure(error.tinkLinkError))
            }
            task?.callCanceller = nil
        })

        return task
    }

    /// Update the user's credentials.
    ///
    /// Required scopes:
    /// - credentials:write
    ///
    /// Use this when you need to update any of the fields on the credentials. Updating a credentials will also trigger a refresh.
    ///
    /// - Parameters:
    ///   - credentials: Credentials that needs to be updated.
    ///   - form: This is a form with fields from the Provider to which the credentials belongs to.
    ///   - shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Determines how the task handles the case when a user doesn't have the required authentication app installed.
    ///   - authenticationHandler: The block that will execute when the credentials needs some sort of authentication from the end user.
    ///   - task: The authentication task that needs to be handled.
    ///   - progressHandler: The block to execute with progress information about the credential's status.
    ///   - status: Indicates the state of a credentials being updated.
    ///   - completion: The block to execute when the credentials has been updated successfully or if it failed.
    ///   - result: A result with either an updated credentials if the update succeeded or an error if failed.
    /// - Returns: The update credentials task.
    @discardableResult
    public func update(
        _ credentials: Credentials,
        form: Form? = nil,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool = true,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        progressHandler: @escaping (_ status: UpdateCredentialsTask.Status) -> Void = { _ in },
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable {
        let id = UUID()

        let task = UpdateCredentialsTask(
            credentials: credentials,
            credentialsService: service,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            appUri: appURI,
            progressHandler: progressHandler,
            authenticationHandler: authenticationHandler,
            completion: { [weak self] result in
                completion(result.mapError(\.tinkLinkError))
                self?.cancellables[id] = nil
            }
        )

        task.pollingStrategy = pollingStrategy
        cancellables[id] = task

        task.callCanceller = service.update(
            id: credentials.id,
            providerName: credentials.providerName,
            appURI: appURI,
            callbackURI: callbackURI,
            fields: form?.makeFields() ?? [:],
            completion: { [weak task] result in
                switch result {
                case .success:
                    task?.startObserving()
                case .failure(let error):
                    completion(.failure(error.tinkLinkError))
                }
                task?.callCanceller = nil
            }
        )

        return task
    }

    /// Delete the user's credentials.
    ///
    /// Required scopes:
    /// - credentials:write
    ///
    /// - Parameters:
    ///   - credentials: The credentials to delete.
    ///   - completion: The block to execute when the credentials has been deleted successfully or if it failed.
    ///   - result: A result representing that the delete succeeded or an error if failed.
    /// - Returns: A cancellation handler.
    @discardableResult
    public func delete(_ credentials: Credentials, completion: @escaping (_ result: Result<Void, Swift.Error>) -> Void) -> RetryCancellable? {
        return service.delete(id: credentials.id) { result in
            completion(result.mapError(\.tinkLinkError))
        }
    }

    // MARK: - Authenticate Credentials

    /// Authenticate the user's `OPEN_BANKING` access type credentials.
    ///
    /// Required scopes:
    /// - credentials:refresh
    ///
    /// This will return an error if the credentials is not connected to a provider with the access type `.openBanking`.
    ///
    /// - Parameters:
    ///   - credentials: Credentials that needs to be authenticated.
    ///   - shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Determines how the task handles the case when a user doesn't have the required authentication app installed.
    ///   - authenticationHandler: The block that will execute when the credentials needs some sort of authentication from the end user.
    ///   - task: The authentication task that needs to be handled.
    ///   - progressHandler: The block to execute with progress information about the credential's status.
    ///   - status: Indicates the state of a credentials being authenticated.
    ///   - completion: The block to execute when the credentials has been authenticated successfully or if it failed.
    ///   - result: A result representing that the authentication succeeded or an error if failed.
    /// - Returns: The authenticate credentials task.
    @discardableResult
    public func authenticate(
        _ credentials: Credentials,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool = true,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        progressHandler: @escaping (_ status: AuthenticateCredentialsTask.Status) -> Void = { _ in },
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable {
        let id = UUID()

        let task = RefreshCredentialsTask(
            credentials: credentials,
            credentialsService: service,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            appUri: appURI,
            progressHandler: progressHandler,
            authenticationHandler: authenticationHandler,
            completion: { [weak self] result in
                completion(result.mapError(\.tinkLinkError))
                self?.cancellables[id] = nil
            }
        )

        task.pollingStrategy = pollingStrategy
        cancellables[id] = task

        task.callCanceller = service.authenticate(id: credentials.id, completion: { [weak task] result in
            switch result {
            case .success:
                task?.startObserving()
            case .failure(let error):
                completion(.failure(error.tinkLinkError))
            }
            task?.callCanceller = nil
        })

        return task
    }
}
