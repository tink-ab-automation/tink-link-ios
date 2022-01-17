import Foundation

public final class TinkLinkSessionManager: SessionManager {
    let authorizationContext: AuthorizationContext
    let consentContext: ConsentContext
    let credentialsContext: CredentialsContext
    let providerContext: ProviderContext

    fileprivate var uiTaskCount = 0

    public init(tink: Tink = .shared) {
        self.authorizationContext = AuthorizationContext(tink: tink)
        self.consentContext = ConsentContext(tink: tink)
        self.credentialsContext = CredentialsContext(tink: tink)
        self.providerContext = ProviderContext(tink: tink)
    }
}

extension Tink {
    private var tinkLinkSessionManager: TinkLinkSessionManager {
        var sessionManager: TinkLinkSessionManager
        if let tinkLinkSessionManager = sessionManagers.compactMap({ $0 as? TinkLinkSessionManager }).first {
            sessionManager = tinkLinkSessionManager
        } else {
            let tinkLinkSessionManager = TinkLinkSessionManager(tink: self)
            sessionManagers.append(tinkLinkSessionManager)
            sessionManager = tinkLinkSessionManager
        }
        return sessionManager
    }

    public var authorizationContext: AuthorizationContext {
        return tinkLinkSessionManager.authorizationContext
    }

    public var consentContext: ConsentContext {
        return tinkLinkSessionManager.consentContext
    }

    public var credentialsContext: CredentialsContext {
        return tinkLinkSessionManager.credentialsContext
    }

    public var providerContext: ProviderContext {
        return tinkLinkSessionManager.providerContext
    }
}

extension Tink {
    public func _beginUITask() {
        tinkLinkSessionManager.uiTaskCount += 1
        updateSDKName()
    }

    public func _endUITask() {
        tinkLinkSessionManager.uiTaskCount -= 1
        updateSDKName()
    }

    private func updateSDKName() {
        _sdkName = tinkLinkSessionManager.uiTaskCount > 0 ? "Tink Link UI iOS" : "Tink Link iOS"
    }
}
