import Foundation
import Protoquest

extension ValorantClient {
	public func getLoadout() async throws -> Loadout {
		try await send(LoadoutRequest(playerID: userID))
	}
	
	public func updateLoadout(to loadout: Loadout) async throws -> Loadout {
		try await send(LoadoutUpdateRequest(playerID: userID, loadout: loadout))
	}
	
	struct LoadoutRequest: GetJSONRequest, GameDataRequest {
		var playerID: Player.ID
		
		var path: String {
			"/personalization/v2/players/\(playerID)/playerloadout"
		}
		
		typealias Response = Loadout
		
		func decodeResponse(from raw: Protoresponse) throws -> Loadout {
			do {
				return try raw.decodeJSON()
			} catch {
				if
					let string = try? raw.decodeString(using: .utf8),
					string.contains("00000000-0000-0000-0000-000000000000")
				{
					throw Loadout.FetchError.uninitialized(playerID)
				}
				throw error
			}
		}
	}
	
	struct LoadoutUpdateRequest: JSONJSONRequest, GameDataRequest {
		var playerID: Player.ID
		var loadout: Loadout
		
		var body: Loadout { loadout }
		var httpMethod: String { "PUT" }
		
		var path: String {
			"/personalization/v2/players/\(playerID)/playerloadout"
		}
		
		typealias Response = Loadout
	}
}

extension Loadout {
	public enum FetchError: Error, LocalizedError {
		/// Thrown for loadouts initialized to the default zeroed-out UUIDs and missing properties.
		/// If you get this, you've likely signed into the wrong account (or somehow fetched data for the wrong region).
		case uninitialized(Player.ID)
		
		public var errorDescription: String? {
			switch self {
			case .uninitialized:
				return "It looks like this account has never played Valorant in this region!"
			}
		}
	}
}

public struct Loadout: Codable {
	public var subject: User.ID
	/// incremented every time the loadout is changed
	public var version: Int
	public var isIncognito: Bool
	public var identity: Identity
	public var guns: [Gun]
	public var sprays: [EquippedSpray]
	
	private enum CodingKeys: String, CodingKey {
		case subject = "Subject"
		case version = "Version"
		case identity = "Identity"
		case guns = "Guns"
		case sprays = "Sprays"
		case isIncognito = "Incognito"
	}
	
	public struct Gun: Codable {
		public var id: Weapon.ID
		public var skin: Skin
		public var buddy: Buddy?
		
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			id = try container.decodeValue(forKey: .id)
			
			let nested = try decoder.singleValueContainer()
			skin = try nested.decode(Skin.self)
			buddy = container.allKeys.contains(.buddyID) ? try nested.decode(Buddy.self) : nil
		}
		
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(id, forKey: .id)
			
			try skin.encode(to: encoder)
			try buddy?.encode(to: encoder)
		}
		
		private enum CodingKeys: String, CodingKey {
			case id = "ID"
			case buddyID = "CharmID"
		}
		
		public struct Skin: Codable {
			public var skin: Weapon.Skin.ID
			public var level: Weapon.Skin.Level.ID
			/// can be nil for freshly-bought lvl1 skins!
			public var chroma: Weapon.Skin.Chroma.ID?
			
			public init(
				skin: Weapon.Skin.ID,
				level: Weapon.Skin.Level.ID,
				chroma: Weapon.Skin.Chroma.ID?
			) {
				self.skin = skin
				self.level = level
				self.chroma = chroma
			}
			
			private enum CodingKeys: String, CodingKey {
				case skin = "SkinID"
				case level = "SkinLevelID"
				case chroma = "ChromaID"
			}
		}
		
		public struct Buddy: Equatable, Codable {
			public var buddy: Weapon.Buddy.ID
			public var level: Weapon.Buddy.Level.ID
			public var instance: Weapon.Buddy.Instance.ID
			
			public init(
				buddy: Weapon.Buddy.ID,
				level: Weapon.Buddy.Level.ID,
				instance: Weapon.Buddy.Instance.ID
			) {
				self.buddy = buddy
				self.level = level
				self.instance = instance
			}
			
			private enum CodingKeys: String, CodingKey {
				case buddy = "CharmID"
				case level = "CharmLevelID"
				case instance = "CharmInstanceID"
			}
		}
	}
	
	public struct EquippedSpray: Codable {
		public var slot: Spray.Slot.ID
		public var spray: Spray.ID
		
		private enum CodingKeys: String, CodingKey {
			case slot = "EquipSlotID"
			case spray = "SprayID"
		}
	}
	
	public struct Identity: Codable {
		public var card: PlayerCard.ID
		public var title: PlayerTitle.ID
		public var levelBorder: LevelBorder.ID
		public var isLevelHidden: Bool
		
		private enum CodingKeys: String, CodingKey {
			case card = "PlayerCardID"
			case title = "PlayerTitleID"
			case levelBorder = "PreferredLevelBorderID"
			case isLevelHidden = "HideAccountLevel"
		}
	}
}

extension LowercaseUUID {
	// i DESPISE when people (riot…) do this. null exists for a reason!!!!
	private static let stupidNullID = Self(.init(uuidString: "00000000-0000-0000-0000-000000000000")!)
	
	public var isPseudoNull: Bool {
		self == .stupidNullID
	}
}

extension ObjectID where RawID == LowercaseUUID {
	/// player cards/titles/level borders are initially set to an all-zeroes ID rather than null for no good reason.
	public var isPseudoNull: Bool {
		rawID.isPseudoNull
	}
}

public struct UpdatableLoadout {
	public let subject: User.ID
	public var isIncognito: Bool
	public var identity: Loadout.Identity
	public var guns: [Weapon.ID: Loadout.Gun]
	public var sprays: [Spray.Slot.ID: Spray.ID]
	
	public init(_ loadout: Loadout) {
		subject = loadout.subject
		isIncognito = loadout.isIncognito
		identity = loadout.identity
		guns = .init(uniqueKeysWithValues: loadout.guns.map { ($0.id, $0) })
		sprays = .init(uniqueKeysWithValues: loadout.sprays.map { ($0.slot, $0.spray) })
	}
	
	public func currentWeapon(for instance: Weapon.Buddy.Instance.ID) -> Weapon.ID? {
		guns.values.first { $0.buddy?.instance == instance }?.id
	}
}

extension Loadout {
	public init(_ loadout: UpdatableLoadout) {
		subject = loadout.subject
		version = -1
		isIncognito = loadout.isIncognito
		identity = loadout.identity
		guns = .init(loadout.guns.values)
		sprays = .init(loadout.sprays.map(Loadout.EquippedSpray.init))
	}
}
