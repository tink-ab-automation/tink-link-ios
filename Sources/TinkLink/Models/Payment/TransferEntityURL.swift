import Foundation

public struct TransferEntityURI {
    public struct Kind: ExpressibleByStringLiteral {
        public init(stringLiteral value: String) {
            self.value = value
        }

        public init(_ value: String) {
            self.value = value
        }

        public let value: String
    }

    public init?(kind: Kind, accountNumber: String) {
        if let uri = URL(string: "\(kind.value)://\(accountNumber)") {
            self.init(uri: uri)
        } else {
            return nil
        }
    }

    init(uri: URL) {
        self.uri = uri
    }

    let uri: URL
}

extension TransferEntityURI {
    init?(account: Account) {
        if let uri = account.transferSourceIdentifiers?.first {
            self.init(uri: uri)
        } else {
            return nil
        }
    }
}

extension TransferEntityURI {
    init?(beneficiary: Beneficiary) {
        if let uri = beneficiary.uri {
            self.init(uri: uri)
        } else {
            return nil
        }
    }
}
