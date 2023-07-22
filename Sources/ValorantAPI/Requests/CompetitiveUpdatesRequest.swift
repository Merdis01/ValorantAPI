import Foundation
import HandyOperators
import Protoquest

extension ValorantClient {
	/// Fetches competitive updates, which is basically just your match history with extra data on competitive changes.
	///
	/// Note that this is not limited to competitive games by default, though it is filterable by queue.
	public func getCompetitiveUpdates(
		userID: Player.ID? = nil,
		queue: QueueID? = nil,
		startIndex: Int = 0,
		endIndex: Int? = nil
	) async throws -> [CompetitiveUpdate] {
		do {
			return try await send(CompetitiveUpdatesRequest(
				userID: userID ?? self.userID,
				startIndex: startIndex, endIndex: endIndex ?? (startIndex + 20),
				queue: queue
			)).matches
		} catch APIError.badResponseCode(400, _, let riotError?)
					where riotError.errorCode == "BAD_PARAMETER" {
			return [] // probably just no matches this far back yet
		}
	}
}

private struct CompetitiveUpdatesRequest: GetJSONRequest, GameDataRequest {
	var userID: Player.ID
	var startIndex = 0
	var endIndex = 20
	var queue: QueueID?
	
	var path: String {
		"/mmr/v1/players/\(userID)/competitiveupdates"
	}
	
	var urlParams: [URLParameter] {
		("startIndex", startIndex)
		("endIndex", endIndex)
		queue.map { ("queue", $0.rawValue) }
	}
	
	struct Response: Decodable {
		var version: Int
		var subject: Player.ID
		var matches: [CompetitiveUpdate]
		
		private enum CodingKeys: String, CodingKey {
			case version = "Version"
			case subject = "Subject"
			case matches = "Matches"
		}
	}
}
