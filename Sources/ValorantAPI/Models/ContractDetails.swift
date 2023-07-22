import Foundation
import ErgonomicCodable

public struct ContractDetails: Equatable, Codable {
	public var contracts: [Contract]
	public var activeSpecialContract: Contract.ID?
	public var missions: [Mission]
	public var missionMetadata: MissionMetadata
	// Technically this object also lists processed matches, but I don't care about those right now and they'd be a significant extra effort to add.
	
	private enum CodingKeys: String, CodingKey {
		case contracts = "Contracts"
		case activeSpecialContract = "ActiveSpecialContract"
		case missions = "Missions"
		case missionMetadata = "MissionMetadata"
	}
	
	public struct MissionMetadata: Equatable, Codable {
		/// `nil` when not completed
		public var hasCompletedNewPlayerExperience: Bool?
		/// The activation date for the last set of weeklies the user has completed.
		/// - Note: Can be `nil` for users that haven't completed any weeklies this act.
		public var weeklyCheckpoint: Date?
		/// When the next set of weekly missions will become available.
		public var weeklyRefillTime: Date?
		
		private enum CodingKeys: String, CodingKey {
			case hasCompletedNewPlayerExperience = "NPECompleted"
			case weeklyCheckpoint = "WeeklyCheckpoint"
			case weeklyRefillTime = "WeeklyRefillTime"
		}
	}
}

public struct Contract: Equatable, Codable, Identifiable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	public var id: ID
	
	public var progression: Progression
	public var levelReached: Int
	public var progressionTowardsNextLevel: Int
	
	public static func unprogressed(with id: ID) -> Self {
		.init(
			id: id,
			progression: .init(totalEarned: 0, highestRewardedLevel: [:]),
			levelReached: 0,
			progressionTowardsNextLevel: 0
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "ContractDefinitionID"
		case progression = "ContractProgression"
		case levelReached = "ProgressionLevelReached"
		case progressionTowardsNextLevel = "ProgressionTowardsNextLevel"
	}
	
	public struct Progression: Equatable, Codable {
		public var totalEarned: Int
		@StringKeyedDictionary
		public var highestRewardedLevel: [LowercaseUUID: RewardedLevel]
		
		private enum CodingKeys: String, CodingKey {
			case totalEarned = "TotalProgressionEarned"
			case highestRewardedLevel = "HighestRewardedLevel"
		}
		
		public struct RewardedLevel: Equatable, Codable {
			public var amount: Int
			public var version: Int
			
			private enum CodingKeys: String, CodingKey {
				case amount = "Amount"
				case version = "Version"
			}
		}
	}
}

public extension Contract.ID {
	static let freeAgents = Self("a3dd5293-4b3d-46de-a6d7-4493f0530d9b")!
}

public struct Mission: Equatable, Codable, Identifiable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	public var id: ID
	
	@StringKeyedDictionary
	public var objectiveProgress: [Objective.ID: Int]
	public var isComplete: Bool
	public var expirationTime: Date?
	
	private enum CodingKeys: String, CodingKey {
		case id = "ID"
		case objectiveProgress = "Objectives"
		case isComplete = "Complete"
		case expirationTime = "ExpirationTime"
	}
}

public enum Objective {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public struct AgentContractProgress: Codable {
	var counters: [Counter]
	
	private enum CodingKeys: String, CodingKey {
		case counters = "Counters"
	}
	
	struct Counter: Codable {
		var id: ObjectID<Self, LowercaseUUID>
		var value: Int
		
		private enum CodingKeys: String, CodingKey {
			case id = "ID"
			case value = "Value"
		}
	}
}

public struct DailyTicketProgress: Codable {
	public static let zero = Self(
		remainingTime: 0,
		milestones: .init(repeating: .zero, count: 4)
	)
	
	public var remainingTime: TimeInterval
	public var milestones: [Milestone]
	
	private enum CodingKeys: String, CodingKey {
		case remainingTime = "RemainingLifetimeSeconds"
		case milestones = "Milestones"
	}
	
	public struct Milestone: Codable {
		public static let zero = Self(progress: 0, wasRedeemed: false)
		
		/// 0-4
		public var progress: Int
		/// honestly i can't figure out the logic behind when this is set to true vs left as false
		public var wasRedeemed: Bool
		public var isComplete: Bool { progress >= 4 }
		
		private enum CodingKeys: String, CodingKey {
			case progress = "Progress"
			case wasRedeemed = "BonusApplied"
		}
	}
}
