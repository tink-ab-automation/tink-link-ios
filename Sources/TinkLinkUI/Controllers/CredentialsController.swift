import TinkLink
import Foundation

final class CredentialsController {
    let tink: Tink
    private(set) lazy var credentialsContext = CredentialsContext(tink: tink)
    var newlyAddedFailedCredentialsID: [Credentials.ID: Error] = [:]

    init(tink: Tink) {
        self.tink = tink
    }

    func credentials(id: Credentials.ID, completion: @escaping (Result<Credentials, Error>) -> Void) {
        tink._beginUITask()
        defer { tink._endUITask() }
        credentialsContext.fetchCredentials(withID: id, completion: completion)
    }

    func addCredentials(
        _ provider: Provider,
        form: Form,
        refreshableItems: RefreshableItems,
        progressHandler: @escaping (AddCredentialsTask.Status) -> Void,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        completion: @escaping (_ result: Result<Credentials, Error>) -> Void
    ) -> Cancellable? {
        tink._beginUITask()
        return credentialsContext.add(
            for: provider,
            form: form,
            refreshableItems: refreshableItems,
            completionPredicate: AddCredentialsTask.CompletionPredicate(successPredicate: .updated, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false),
            authenticationHandler: authenticationHandler,
            progressHandler: progressHandler,
            completion: { [weak tink] result in
                tink?._endUITask()
                completion(result)
            }
        )
    }

    func update(
        _ credentials: Credentials,
        form: Form,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool,
        progressHandler: @escaping (_ status: UpdateCredentialsTask.Status) -> Void,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable? {
        tink._beginUITask()
        return credentialsContext.update(
            credentials,
            form: form,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            authenticationHandler: authenticationHandler,
            progressHandler: progressHandler,
            completion: { [weak tink] result in
                tink?._endUITask()
                completion(result)
            }
        )
    }

    func refresh(
        _ credentials: Credentials,
        authenticate: Bool,
        refreshableItems: RefreshableItems,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool,
        progressHandler: @escaping (_ status: RefreshCredentialsTask.Status) -> Void,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable {
        tink._beginUITask()
        return credentialsContext.refresh(
            credentials,
            authenticate: authenticate,
            refreshableItems: refreshableItems,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            authenticationHandler: authenticationHandler,
            progressHandler: progressHandler,
            completion: { [weak tink] result in
                tink?._endUITask()
                completion(result)
            }
        )
    }

    public func authenticate(
        _ credentials: Credentials,
        shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool,
        progressHandler: @escaping (_ status: AuthenticateCredentialsTask.Status) -> Void,
        authenticationHandler: @escaping AuthenticationTaskHandler,
        completion: @escaping (_ result: Result<Credentials, Swift.Error>) -> Void
    ) -> Cancellable {
        tink._beginUITask()
        return credentialsContext.authenticate(
            credentials,
            shouldFailOnThirdPartyAppAuthenticationDownloadRequired: shouldFailOnThirdPartyAppAuthenticationDownloadRequired,
            authenticationHandler: authenticationHandler,
            progressHandler: progressHandler,
            completion: { [weak tink] result in
                tink?._endUITask()
                completion(result)
            }
        )
    }
}
