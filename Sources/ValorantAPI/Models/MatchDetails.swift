import Foundation
import HandyOperators
import ErgonomicCodable

public struct MatchDetails: Codable, Identifiable {
	public var matchInfo: MatchInfo
	public var players: [Player]
	public var teams: [Team]
	public var roundResults: [RoundResult]
	public var kills: [Kill]
	
	public var id: Match.ID { matchInfo.id }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		matchInfo = try container.decodeValue(forKey: .matchInfo)
		players = try container.decodeValue(forKey: .players)
		teams = try container.decodeValue(forKey: .teams)
		roundResults = try container.decode([_RoundResult].self, forKey: .roundResults)
			.map(\.result)
		kills = try container.decodeValue(forKey: .kills)
	}
}

extension MatchDetails {
	/// - returns (hardcoded) information on round structure, if game mode is known to work in rounds
	public var roundStructure: RoundStructure? {
		switch matchInfo.modeID {
		case .standard:
			return .init(roundsPerHalf: 12, hasEqualOvertime: true)
		case .spikeRush:
			return .init(roundsPerHalf: 3)
		case .replication, .swiftplay:
			return .init(roundsPerHalf: 4)
		default:
			return nil
		}
	}
	
	public struct RoundStructure {
		public var roundsPerHalf: Int
		public var hasEqualOvertime = false
		
		public func areRolesSwapped(inRound round: Int) -> Bool {
			if round < roundsPerHalf * 2 {
				return round >= roundsPerHalf
			} else if hasEqualOvertime {
				return round % 2 == 1
			} else {
				return true
			}
		}
	}
}

public protocol BasicMatchInfo {
	var id: Match.ID { get }
	var provisioningFlowID: ProvisioningFlow.ID { get }
	var queueID: QueueID? { get }
	var modeID: GameMode.ID { get }
	var mapID: MapID { get }
	var isRanked: Bool { get }
}

public struct MatchInfo: Codable, Identifiable, BasicMatchInfo {
	public var id: Match.ID
	public var mapID: MapID
	public var gameVersion: String
	public var gameLengthMillis: Int
	public var gameStart: Date
	public var provisioningFlowID: ProvisioningFlow.ID
	public var isCompleted: Bool
	@SpecialOptional(.emptyString)
	public var queueID: QueueID?
	public var modeID: GameMode.ID
	public var isRanked: Bool
	public var seasonID: Season.ID
	
	public var gameLength: TimeInterval {
		TimeInterval(gameLengthMillis) / 1000
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "matchId"
		case mapID = "mapId"
		case gameVersion
		case gameLengthMillis
		case gameStart = "gameStartMillis"
		case provisioningFlowID
		case isCompleted
		case queueID
		case modeID = "gameMode"
		case isRanked
		case seasonID = "seasonId"
	}
}

public struct Team: Identifiable, Codable {
	public typealias ID = ObjectID<Self, String>
	
	public var id: ID
	public var won: Bool
	public var roundsPlayed, roundsWon: Int
	public var pointCount: Int
	
	private enum CodingKeys: String, CodingKey {
		case id = "teamId"
		case won
		case roundsPlayed
		case roundsWon
		case pointCount = "numPoints"
	}
}

public extension Team.ID {
	static let blue = Self("Blue")!
	static let red = Self("Red")!
	static let neutral = Self("Neutral")!
}

public struct RoundResult: Codable {
	public var number: Int
	
	public var outcome: Outcome
	public var outcomeCode: String
	public var ceremony: String
	public var winningTeam: Team.ID
	
	public var playerEconomies: [PlayerEconomy]?
	public var playerScores: [PlayerScore]?
	public var playerStats: [PlayerStats]
	
	public var plantSite: String?
	public var plant: BombAction?
	public var defusal: BombAction?
	
	public struct BombAction: Codable {
		public var roundTimeMillis: Int
		public var position: Position
		public var playerLocations: [PlayerLocation]
		public var actor: Player.ID
	}
	
	public struct PlayerEconomy: Codable {
		public var subject: Player.ID?
		public var spent, remaining: Int
		public var loadoutValue: Int
		@SpecialOptional(.emptyString)
		public var weapon: Weapon.ID?
		@SpecialOptional(.emptyString)
		public var armor: Armor.ID?
		// no info on sidearms unfortunately
	}
	
	public struct PlayerScore: Codable {
		public var subject: Player.ID
		public var score: Int
	}
	
	public struct PlayerStats: Codable {
		public var subject: Player.ID
		
		public var kills: [Kill]
		public var damageDealt: [Damage]
		public var combatScore: Int
		public var economy: PlayerEconomy
		
		public var wasAFK: Bool
		public var wasPenalized: Bool
		public var stayedInSpawn: Bool
		
		private enum CodingKeys: String, CodingKey {
			case subject
			
			case kills
			case damageDealt = "damage"
			case combatScore = "score"
			case economy
			// there's also a key here 'abilities' whose nested values always seem to be null, at least in the games i checked lol
			
			case wasAFK = "wasAfk"
			case wasPenalized
			case stayedInSpawn
		}
		
		public struct Damage: Codable {
			public var receiver: Player.ID
			public var damage: Int
			public var headshots: Int
			public var bodyshots: Int
			public var legshots: Int
		}
	}
	
	// This actually handles the timer expired case, unlike the outcome code.
	public struct Outcome: SimpleRawWrapper {
		public static let eliminated = Self("Eliminated")
		public static let timerExpired = Self("Round timer expired")
		public static let bombDetonated = Self("Bomb detonated")
		public static let bombDefused = Self("Bomb defused")
		public static let surrendered = Self("Surrendered")
		
		public var rawValue: String
		
		public init(_ rawValue: String) {
			self.rawValue = rawValue
		}
	}
}

public struct PlayerLocation: Codable {
	public var subject: Player.ID
	/// in radians
	public var angle: Double
	public var position: Position
	
	private enum CodingKeys: String, CodingKey {
		case subject
		case angle = "viewRadians"
		case position = "location"
	}
}

public struct Position: Codable, Hashable {
	public var x, y: Double
}

public struct Kill: Codable {
	public var round: Int?
	public var roundTimeMillis: Int
	public var gameTimeMillis: Int
	
	@SpecialOptional(.emptyString)
	public var killer: Player.ID?
	public var victim: Player.ID
	public var assistants: [Player.ID]
	
	public var victimPosition: Position
	public var playerLocations: [PlayerLocation]
	public var finishingDamage: Damage
	
	private enum CodingKeys: String, CodingKey {
		case round
		case roundTimeMillis = "roundTime"
		case gameTimeMillis = "gameTime"
		
		case killer
		case victim
		case assistants
		
		case victimPosition = "victimLocation"
		case playerLocations
		case finishingDamage
	}
	
	public struct Damage: Codable {
		public var type: DamageType
		/// weapon id or ability name/"id", not sure about fall damage
		public var source: String
		public var wasInSecondaryFireMode: Bool
		
		private static let abilityAliases: [String: String] = [
			// riot changed this at some point…
			"GrenadeAbility": "Grenade",
			"Primary": "Grenade",
		]
		
		/// if this damage was dealt using an ability, this takes care of remapping riot's ever-changing aliases to the ability slot names
		public var remappedAbilitySlot: String {
			Self.abilityAliases[source] ?? source
		}
		
		private enum CodingKeys: String, CodingKey {
			case type = "damageType"
			case source = "damageItem"
			case wasInSecondaryFireMode = "isSecondaryFireMode"
		}
		
		public struct DamageType: SimpleRawWrapper {
			public static let bomb = Self("Bomb")
			public static let weapon = Self("Weapon")
			public static let melee = Self("Melee")
			public static let ability = Self("Ability")
			public static let fall = Self("Fall")
			// golden gun?
			
			public var rawValue: String
			
			public init(_ rawValue: String) {
				self.rawValue = rawValue
			}
		}
	}
}

// Codable sure is a pain sometimes

private struct _RoundResult: Decodable {
	var result: RoundResult
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if decoder.isDecodingFromRiot {
			result = try container.decode(APIRoundResult.self)
				.makeModel(in: container)
		} else {
			result = try container.decode(RoundResult.self)
		}
	}
}

private struct APIRoundResult: Decodable {
	var number: Int
	
	var outcome: RoundResult.Outcome
	var outcomeCode: String
	var ceremony: String
	var winningTeam: Team.ID
	
	var playerEconomies: [RoundResult.PlayerEconomy]?
	var playerScores: [RoundResult.PlayerScore]?
	var playerStats: [RoundResult.PlayerStats]
	
	var plantSite: String
	var plantTimeMillis: Int
	var plantLocation: Position
	var plantPlayerLocations: [PlayerLocation]?
	var planter: Player.ID?
	
	var defuseTimeMillis: Int
	var defuseLocation: Position
	var defusePlayerLocations: [PlayerLocation]?
	var defuser: Player.ID?
	
	func makeModel(in container: SingleValueDecodingContainer) throws -> RoundResult {
		.init(
			number: number,
			outcome: outcome,
			outcomeCode: outcomeCode,
			ceremony: ceremony,
			winningTeam: winningTeam,
			playerEconomies: playerEconomies,
			playerScores: playerScores,
			playerStats: playerStats,
			plantSite: plantSite.isEmpty ? nil : plantSite,
			plant: try planter.map {
				try .init(
					roundTimeMillis: plantTimeMillis,
					position: plantLocation,
					playerLocations: plantPlayerLocations ??? DecodingError.dataCorruptedError(
						in: container,
						debugDescription: "planter is present without plantPlayerLocations"
					),
					actor: $0
				)
			},
			defusal: try defuser.map {
				try .init(
					roundTimeMillis: defuseTimeMillis,
					position: defuseLocation,
					playerLocations: defusePlayerLocations ??? DecodingError.dataCorruptedError(
						in: container,
						debugDescription: "defuser is present without defusePlayerLocations"
					),
					actor: $0
				)
			}
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case number = "roundNum"
		
		case outcome = "roundResult"
		case outcomeCode = "roundResultCode"
		case ceremony = "roundCeremony"
		case winningTeam
		
		case playerEconomies
		case playerScores
		case playerStats
		
		case plantSite
		case plantTimeMillis = "plantRoundTime"
		case plantLocation
		case plantPlayerLocations
		case planter = "bombPlanter"
		
		case defuseTimeMillis = "defuseRoundTime"
		case defuseLocation
		case defusePlayerLocations
		case defuser = "bombDefuser"
	}
}
