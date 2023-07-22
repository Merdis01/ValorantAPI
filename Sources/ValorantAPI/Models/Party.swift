import Foundation
import ErgonomicCodable

public struct Party: Identifiable, Codable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public var id: ID
	public var members: [Member]
	public var state: State
	public var accessibility: Accessibility
	public var eligibleQueues: [QueueID]?
	/// the last time this party entered the queue (even if it's not currently in a queue—check the state for that)
	public var queueEntryTime: Date
	public var matchmakingData: MatchmakingData
	// there's custom game data here too—handle that?
	
	private enum CodingKeys: String, CodingKey {
		case id = "ID"
		case members = "Members"
		case state = "State"
		case accessibility = "Accessibility"
		case eligibleQueues = "EligibleQueues"
		case queueEntryTime = "QueueEntryTime"
		case matchmakingData = "MatchmakingData"
	}
	
	public struct State: SimpleRawWrapper {
		public static let `default` = Self("DEFAULT")
		public static let inMatchmaking = Self("MATCHMAKING")
		// TODO: in-game state?
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	public struct Member: Identifiable, Codable {
		public var id: Player.ID
		public var identity: Player.Identity
		public var isReady: Bool
		private var _isOwner: Bool?
		public var isModerator: Bool
		
		public var isOwner: Bool {
			get { _isOwner == true }
			set { _isOwner = newValue }
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "Subject"
			case identity = "PlayerIdentity"
			case isReady = "IsReady"
			case _isOwner = "IsOwner"
			case isModerator = "IsModerator"
		}
	}
	
	public enum Accessibility: String, Codable {
		case open = "OPEN"
		case closed = "CLOSED"
	}
	
	public struct MatchmakingData: Codable {
		public var queueID: QueueID
		/// RR penalty for skill disparity in Competitive
		public var rrPenalty: Double // TODO: is this actually an int?
		
		private enum CodingKeys: String, CodingKey {
			case queueID = "QueueID"
			case rrPenalty = "SkillDisparityRRPenalty"
		}
	}
}
