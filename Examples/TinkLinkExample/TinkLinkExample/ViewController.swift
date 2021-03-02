import UIKit
import TinkLink
import TinkLinkUI

class ViewController: UIViewController {
    enum AuthorizationKind {
        case temporaryUser
        case authorizationCode(String)
        case accessToken(String)

        init() {
            if let code = ProcessInfo.processInfo.environment["TINK_LINK_EXAMPLE_AUTHORIZATION_CODE"] {
                self = .authorizationCode(code)
            } else if let token = ProcessInfo.processInfo.environment["TINK_LINK_EXAMPLE_ACCESS_TOKEN"] {
                self = .accessToken(token)
            } else {
                self = .temporaryUser
            }
        }
    }

    private let authorizationKind = AuthorizationKind()

    private let configuration = try! Tink.Configuration(
        clientID: ProcessInfo.processInfo.environment["TINK_LINK_EXAMPLE_CLIENT_ID"] ?? "YOUR_CLIENT_ID",
        redirectURI: URL(string: ProcessInfo.processInfo.environment["TINK_LINK_EXAMPLE_REDIRECT_URI"] ?? "tinklink://example")!,
        environment: .production
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        let color = Appearance.provider.colors

        view.backgroundColor = color.background

        let label = UILabel()
        label.text = "Aggregation\n SDK sample app"
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textColor = color.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(showTinkLink), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.setTitle("Start aggregation flow", for: .normal)
        button.setTitleColor(color.buttonLabel, for: .normal)
        button.contentEdgeInsets = .init(top: 0, left: 24, bottom: 0, right: 24)
        button.backgroundColor = color.accent
        button.layer.cornerRadius = 24

        view.addSubview(label)
        view.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            button.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            button.heightAnchor.constraint(equalToConstant: 48),
            button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -48)
        ])
    }

    @objc private func showTinkLink() {
        switch authorizationKind {
        case .temporaryUser:
            showTinkLinkWithTemporaryUser()
        case .authorizationCode(let code):
            showTinkLinkWithAuthorizationCode(code)
        case .accessToken(let token):
            showTinkLinkWithUserSession(token)
        }
    }

    private func showTinkLinkWithTemporaryUser() {
        let market = Market(code: ProcessInfo.processInfo.environment["TINK_LINK_EXAMPLE_MARKET"] ?? "SE")
        let scopes: [Scope] = [
            .statistics(.read),
            .transactions(.read),
            .categories(.read),
            .accounts(.read)
        ]
        let tinkLinkViewController = TinkLinkViewController(configuration: configuration, market: market, scopes: scopes, providerPredicate: .kinds(.all)) { result in
            print(result)
        }
        present(tinkLinkViewController, animated: true)
    }

    private func showTinkLinkWithAuthorizationCode(_ authorizationCode: String) {
        Tink.configure(with: configuration)
        Tink.shared.authenticateUser(authorizationCode: AuthorizationCode(authorizationCode)) { result in
            DispatchQueue.main.async {
                do {
                    let accessToken = try result.get()
                    Tink.shared.userSession = .accessToken(accessToken.rawValue)
                    let tinkLinkViewController = TinkLinkViewController { result in
                        print(result)
                    }
                    self.present(tinkLinkViewController, animated: true)
                } catch {
                    // Handle error
                }
            }
        }
    }

    private func showTinkLinkWithUserSession(_ accessToken: String) {
        Tink.configure(with: configuration)
        Tink.shared.userSession = .accessToken(accessToken)
        let tinkLinkViewController = TinkLinkViewController(operation: .create(providerPredicate: .kinds(.all))) { result in
            print(result)
        }
        present(tinkLinkViewController, animated: true)
    }
}
