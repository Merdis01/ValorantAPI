import Foundation
import ErgonomicCodable

public struct LivePregameInfo: Codable, Identifiable, BasicMatchInfo {
	public var id: Match.ID
	
	public var team: TeamInfo
	public var observers: [PlayerInfo]
	public var coaches: [PlayerInfo]
	
	public var enemyTeamSize: Int
	public var enemyTeamLockCount: Int
	public var state: State
	public var mapID: MapID
	public var modeID: GameMode.ID
	@SpecialOptional(.emptyString)
	public var queueID: QueueID?
	public var provisioningFlowID: ProvisioningFlow.ID
	public var isRanked: Bool
	public var nanosecondsRemainingInPhase: Int
	
	public var timeRemainingInPhase: TimeInterval {
		TimeInterval(nanosecondsRemainingInPhase) / 1e9
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "ID"
		case team = "AllyTeam"
		case observers = "ObserverSubjects"
		case coaches = "MatchCoaches"
		case enemyTeamSize = "EnemyTeamSize"
		case enemyTeamLockCount = "EnemyTeamLockCount"
		case state = "PregameState"
		case mapID = "MapID"
		case modeID = "Mode"
		case queueID = "QueueID"
		case provisioningFlowID = "ProvisioningFlowID"
		case isRanked = "IsRanked"
		case nanosecondsRemainingInPhase = "PhaseTimeRemainingNS"
	}
	
	public struct State: SimpleRawWrapper {
		public static let agentSelectActive = Self("character_select_active")
		public static let agentSelectFinished = Self("character_select_finished")
		public static let provisioned = Self("provisioned")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	public struct TeamInfo: Codable, Identifiable {
		public var id: Team.ID
		
		public var players: [PlayerInfo]
		
		private enum CodingKeys: String, CodingKey {
			case id = "TeamID"
			case players = "Players"
		}
	}
	
	public struct PlayerInfo: Codable, Identifiable {
		public var id: Player.ID
		
		@SpecialOptional(.emptyString)
		public var agentID: Agent.ID?
		@SpecialOptional(.emptyString)
		public var agentSelectionState: AgentSelectionState?
		public var playerState: PlayerState
		public var identity: Player.Identity
		
		public var isLockedIn: Bool {
			agentSelectionState == .locked
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			case agentID = "CharacterID"
			case agentSelectionState = "CharacterSelectionState"
			case playerState = "PregamePlayerState"
			case identity = "PlayerIdentity"
		}
		
		public struct AgentSelectionState: SimpleRawWrapper {
			public static let selected = Self("selected")
			public static let locked = Self("locked")
			
			public var rawValue: String
			
			public init(_ rawValue: String) {
				self.rawValue = rawValue
			}
		}
		
		public struct PlayerState: SimpleRawWrapper {
			public static let joined = Self("joined")
			
			public var rawValue: String
			
			public init(_ rawValue: String) {
				self.rawValue = rawValue
			}
		}
	}
}
