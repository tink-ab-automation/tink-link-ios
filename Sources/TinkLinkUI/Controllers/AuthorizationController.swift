import TinkLink
import Foundation

final class AuthorizationController {
    let tink: Tink

    private var authorizationContext: AuthorizationContext

    init(tink: Tink) {
        self.tink = tink
        self.authorizationContext = AuthorizationContext(tink: tink)
    }

    @discardableResult
    func authorize(scopes: [Scope], completion: @escaping (_ result: Result<AuthorizationCode, Error>) -> Void) -> RetryCancellable? {
        tink._beginUITask()
        defer { tink._endUITask() }
        return authorizationContext._authorize(scopes: scopes, completion: completion)
    }

    @discardableResult
    func clientDescription(completion: @escaping (Result<ClientDescription, Error>) -> Void) -> RetryCancellable? {
        tink._beginUITask()
        defer { tink._endUITask() }
        return authorizationContext.fetchClientDescription(completion: completion)
    }

    @discardableResult
    public func scopeDescriptions(scopes: [Scope], completion: @escaping (Result<[ScopeDescription], Error>) -> Void) -> RetryCancellable? {
        tink._beginUITask()
        defer { tink._endUITask() }
        return ConsentContext(tink: tink).fetchScopeDescriptions(scopes: scopes, completion: completion)
    }

    func privacyPolicy(for locale: Locale = .current) -> URL {
        return ConsentContext(tink: tink).privacyPolicy(for: locale)
    }

    func termsAndConditions(for locale: Locale = .current) -> URL {
        return ConsentContext(tink: tink).termsAndConditions(for: locale)
    }
}
