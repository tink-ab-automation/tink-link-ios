import Foundation

class AnalyticsAPI {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    func sendRequest(_ request: TinkAnalyticsRequest) {
        var urlRequest = URLRequest(url: URL(string: "https://api.tink.com/link/v1/analytics")!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let body = try? encoder.encode(request) else {
            return
        }

        urlRequest.httpBody = body

        let task = URLSession.shared.dataTask(with: urlRequest)
        task.resume()
    }
}

enum TinkAnalyticsRequest {
    struct ViewEvent: Encodable {
        let appName: String?
        let appIdentifier: String?
        let appVersion: String?
        let market: String?
        let clientId: String
        let sessionId: String
        let isTest: Bool
        let product: String
        let version: String
        let platform: String
        let device: String
        let userId: String
        let providerName: String?
        let credentialsId: String?
        let flow: String
        let view: String
        let timestamp: Date
    }

    struct InteractionEvent: Encodable {
        let appName: String?
        let appIdentifier: String?
        let appVersion: String?
        let market: String?
        let clientId: String
        let sessionId: String
        let userId: String
        let providerName: String?
        let credentialsId: String?
        let label: String?
        let view: String
        let timestamp: Date
        let product: String
        let action: String
        let device: String
    }

    case viewEvent(ViewEvent)
    case interactionEvent(InteractionEvent)
}

extension TinkAnalyticsRequest: Encodable {
    private enum CodingKeys: String, CodingKey {
        case type, viewEvent, interactionEvent
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .interactionEvent(let event):
            try container.encode("INTERACTION_EVENT", forKey: .type)
            try container.encode(event, forKey: .interactionEvent)
        case .viewEvent(let event):
            try container.encode("VIEW_EVENT", forKey: .type)
            try container.encode(event, forKey: .viewEvent)
        }
    }
}
