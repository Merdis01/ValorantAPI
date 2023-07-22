import Foundation
import Protoquest

extension ValorantClient {
	public func getUsers(for ids: [User.ID]) async throws -> [User] {
		try await send(UserInfoRequest(body: ids)).compactMap {
			guard let id = User.ID($0.id) else { return nil } // empty otherwise
			return .init(id: id, gameName: $0.name, tagLine: $0.tag)
		}
	}
}

private struct UserInfoRequest: JSONJSONRequest, GameDataRequest {
	var httpMethod: String { "PUT" }
	
	var path: String { "name-service/v2/players" }
	
	var body: [User.ID]
	
	typealias Response = [OptionalUser]
	
	struct OptionalUser: Decodable {
		var id: String // empty for users who have never played valorant
		var name, tag: String
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			case name = "GameName"
			case tag = "TagLine"
		}
	}
}
