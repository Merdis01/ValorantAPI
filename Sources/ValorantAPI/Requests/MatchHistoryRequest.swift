import Foundation
import HandyOperators
import Protoquest

extension ValorantClient {
	/// Fetches (part of) a match history, optionally filtered to a queue.
	public func getMatchHistory(
		userID: Player.ID? = nil,
		queue: QueueID? = nil,
		startIndex: Int = 0
	) async throws -> [MatchHistoryEntry] {
		try await send(MatchHistoryRequest(
			userID: userID ?? self.userID,
			startIndex: startIndex, endIndex: startIndex + 20,
			queue: queue
		)).history
	}
}

private struct MatchHistoryRequest: GetJSONRequest, GameDataRequest {
	var userID: Player.ID
	var startIndex = 0
	var endIndex = 20
	var queue: QueueID?
	
	var path: String {
		"/match-history/v1/history/\(userID)"
	}
	
	var urlParams: [URLParameter] {
		("startIndex", startIndex)
		("endIndex", endIndex)
		queue.map { ("queue", $0.rawValue) }
	}
	
	struct Response: Decodable {
		var subject: UUID
		var history: [MatchHistoryEntry]
		
		private enum CodingKeys: String, CodingKey {
			case subject = "Subject"
			case history = "History"
		}
	}
}
