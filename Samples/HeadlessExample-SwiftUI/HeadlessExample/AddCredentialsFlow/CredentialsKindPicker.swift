import SwiftUI
import TinkLink

struct CredentialsKindPicker: View {
    var credentialsKinds: [ProviderTree.CredentialsKindNode]

    var body: some View {
        List(credentialsKinds, id: \.id) { credentialsKind in
            NavigationLink(destination: AddCredentialsView(provider: credentialsKind.provider)) {
                switch credentialsKind.credentialsKind {
                case .password:
                    Text("Password")
                case .mobileBankID:
                    Text("Mobile BankID")
                case .thirdPartyAuthentication:
                    Text("Third Party Authentication")
                case .keyfob:
                    Text("Key Fob")
                case .unknown:
                    Text("Unknown")
                @unknown default:
                    Text("Unknown")
                }
            }
        }
        .navigationTitle("Choose Credentials Type")
    }
}
