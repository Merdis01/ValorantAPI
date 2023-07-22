import Foundation

public struct MatchHistoryEntry: Codable, Identifiable {
	public var matchID: Match.ID
	public var gameStartTime: Date
	public var teamID: Team.ID
	
	public var id: Match.ID { matchID }
	
	private enum CodingKeys: String, CodingKey {
		case matchID = "MatchID"
		case gameStartTime = "GameStartTime"
		case teamID = "TeamID"
	}
}
