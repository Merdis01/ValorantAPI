import Foundation
import ErgonomicCodable

public struct LiveGameInfo: Codable, BasicMatchInfo {
	public var id: Match.ID
	
	public var players: [PlayerInfo]
	
	public var state: State
	public var mapID: MapID
	public var modeID: GameMode.ID
	public var provisioningFlowID: ProvisioningFlow.ID
	public var matchmakingData: MatchmakingData?
	public var isReconnectable: Bool
	
	public var queueID: QueueID? {
		matchmakingData?.queueID
	}
	
	public var isRanked: Bool {
		matchmakingData?.isRanked ?? false
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "MatchID"
		
		case players = "Players"
		
		case state = "State"
		case mapID = "MapID"
		case modeID = "ModeID"
		case provisioningFlowID = "ProvisioningFlow"
		case matchmakingData = "MatchmakingData"
		case isReconnectable = "IsReconnectable"
	}
	
	public struct State: SimpleRawWrapper {
		static let inProgress = Self("IN_PROGRESS")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	public struct MatchmakingData: Codable {
		@SpecialOptional(.emptyString)
		public var queueID: QueueID?
		public var isRanked: Bool
		
		private enum CodingKeys: String, CodingKey {
			case queueID = "QueueID"
			case isRanked = "IsRanked"
		}
	}
	
	public struct PlayerInfo: Codable, Identifiable {
		public var id: Player.ID
		
		public var teamID: Team.ID
		/// this is `nil` in the range
		public var agentID: Agent.ID?
		public var identity: Player.Identity
		
		// i'm gonna kill whoever decided to encode not having an agent as empty string rather than null
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.id = try container.decode(Player.ID.self, forKey: .id)
			self.teamID = try container.decode(Team.ID.self, forKey: .teamID)
			self.identity = try container.decode(Player.Identity.self, forKey: .identity)
			
			let rawAgentID = try container.decode(String.self, forKey: .agentID)
			self.agentID = rawAgentID.isEmpty ? nil : try container.decode(Agent.ID.self, forKey: .agentID)
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			
			case teamID = "TeamID"
			case agentID = "CharacterID"
			case identity = "PlayerIdentity"
		}
	}
}
