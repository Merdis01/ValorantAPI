import Foundation
import Protoquest

extension ValorantClient {
	public func getMatchDetails(matchID: Match.ID) async throws -> MatchDetails {
		try await send(MatchDetailsRequest(matchID: matchID))
	}
}

private struct MatchDetailsRequest: GetJSONRequest, GameDataRequest {
	var matchID: Match.ID
	
	var path: String {
		"/match-details/v1/matches/\(matchID)"
	}
	
	typealias Response = MatchDetails
}
