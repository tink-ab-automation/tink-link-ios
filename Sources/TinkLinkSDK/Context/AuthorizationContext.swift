import Foundation

/// An object that you use to authorize for a user with requested scopes.
public final class AuthorizationContext {
    private let tinkLink: TinkLink
    private let service: AuthenticationService

    // MARK: - Creating a Context

    /// Creates a context to authorize for an authorization code for a user with requested scopes.
    ///
    /// - Parameter tinkLink: TinkLink instance, will use the shared instance if nothing is provided.
    /// - Parameter user: `User` that will be used for authorizing scope with the Tink API.
    public init(tinkLink: TinkLink = .shared, user: User) {
        self.tinkLink = tinkLink
        self.service = AuthenticationService(tinkLink: tinkLink, accessToken: user.accessToken)
    }

    // MARK: - Authorizing a User

    /// Creates an authorization code with the requested scopes for the current user
    ///
    /// Once you have received the authorization code, you can exchange it for an access token on your backend and use the access token to access the user's data.
    /// Exchanging the authorization code for an access token requires the use of the client secret associated with your client identifier.
    ///
    /// - Parameter scope: A `TinkLink.Scope` list of OAuth scopes to be requested.
    ///                    The Scope array should never be empty.
    /// - Parameter completion: The block to execute when the authorization is complete.
    /// - Parameter result: Represents either an authorization code if authorization was successful or an error if authorization failed.
    @discardableResult
    func authorize(scope: TinkLink.Scope, completion: @escaping (_ result: Result<AuthorizationCode, Error>) -> Void) -> RetryCancellable? {
        let redirectURI = tinkLink.configuration.redirectURI
        return service.authorize(redirectURI: redirectURI, scope: scope) { result in
            completion(result.map { $0.code })
        }
    }

    /// Lists scope descriptions for the provided scopes.
    ///
    /// - Parameters:
    ///   - scope: A `TinkLink.Scope` list of OAuth scopes to be requested.
    ///            The Scope array should never be empty.
    ///   - completion: The block to execute when the scope descriptions are received or if an error occurred.
    /// - Returns: A Cancellable instance. Call cancel() on this instance if you no longer need the result of the request.
    @discardableResult
    public func scopeDescriptions(scope: TinkLink.Scope, completion: @escaping (Result<[ScopeDescription], Error>) -> Void) -> RetryCancellable {
        let redirectURI = tinkLink.configuration.redirectURI
        return service.scopeDescriptions(scope: scope, redirectURI: redirectURI) { (result) in
            completion(result)
        }
    }

    /// Get a link to the Terms & Conditions for TinkLink.
    ///
    /// - Parameter locale: The locale with the language to use.
    /// - Returns: A URL to the Terms & Conditions.
    /// - Note: Not all languages are supported.
    ///         The link will display the page in English if the requested language is not available.
    public func termsAndConditions(for locale: Locale = .current) -> URL {
         let languageCode = locale.languageCode ?? ""
         return URL(string: "https://link.tink.com/terms-and-conditions/\(languageCode)")!
    }

    /// Get a link to the Privacy Policy for TinkLink.
    ///
    /// - Parameter locale: The locale with the language to use.
    /// - Returns: A URL to the Privacy Policy.
    /// - Note: Not all languages are supported.
    ///         The link will display the page in English if the requested language is not available.
    public func privacyPolicy(for locale: Locale = .current) -> URL {
         let languageCode = locale.languageCode ?? ""
         return URL(string: "https://link.tink.com/privacy-policy/\(languageCode)")!
    }
}
