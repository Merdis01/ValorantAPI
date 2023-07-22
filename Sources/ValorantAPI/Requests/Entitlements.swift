import Foundation
import Protoquest

extension AuthClient {
	func getEntitlementsToken() async throws -> String {
		try await send(EntitlementsTokenRequest()).entitlementsToken
	}
}

private struct EntitlementsTokenRequest: JSONJSONRequest, Encodable, AuthRequest {
	var baseURLOverride: URL? { BaseURLs.entitlementsAPI }
	var path: String { "token/v1" }
	
	struct Response: Decodable {
		var entitlementsToken: String
	}
}
