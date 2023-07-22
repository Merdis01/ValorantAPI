import Foundation
import Protoquest

extension ValorantClient {
	public func getCareerSummary(userID: User.ID? = nil) async throws -> CareerSummary {
		try await send(CareerSummaryRequest(userID: userID ?? self.userID))
	}
}

private struct CareerSummaryRequest: GetJSONRequest, GameDataRequest {
	var userID: Player.ID
	
	var path: String {
		"/mmr/v1/players/\(userID)"
	}
	
	typealias Response = CareerSummary
}
