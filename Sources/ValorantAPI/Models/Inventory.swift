import Foundation

public struct Inventory: Codable {
	public static let starterAgents: Set<Agent.ID> = [.jett, .phoenix, .sova, .brimstone, .sage]
	
	public let purchasedAgents: Set<Agent.ID>
	/// includes starter agents, unlike ``purchasedAgents``
	public let agents: Set<Agent.ID>
	public let cards: Set<PlayerCard.ID>
	public let titles: Set<PlayerTitle.ID>
	public let skinLevels: Set<Weapon.Skin.Level.ID>
	public let skinChromas: Set<Weapon.Skin.Chroma.ID>
	public let sprays: Set<Spray.ID>
	public let contracts: Set<Contract.ID>
	public let buddies: [Weapon.Buddy.Level.ID: [Weapon.Buddy.Instance.ID]]
	
	init(_ raw: APIInventory) {
		let collections = Dictionary(
			uniqueKeysWithValues: raw.collectionsByType
				.map { ($0.id, $0) }
		)
		
		func collectItems<ID>(_ type: ItemType.ID) -> Set<ID>
		where ID: ObjectIDProtocol, ID.RawID == LowercaseUUID {
			Set(collections[type]?.items.lazy.map(\.id).map(ID.init(rawID:)) ?? [])
		}
		
		func collectItems<Item: InventoryItem>() -> Set<Item.ID> {
			let ids = collections[Item.typeID]?.items
				.lazy
				.map(\.id)
				.map(Item.ID.init(rawID:))
			return ids.map(Set.init) ?? []
		}
		
		purchasedAgents = collectItems(.agents)
		cards = collectItems(.cards)
		titles = collectItems(.titles)
		skinLevels = collectItems(.skinLevels)
		skinChromas = collectItems(.skinChromas)
		sprays = collectItems(.sprays)
		contracts = collectItems(.contracts)
		buddies = collections[.buddies]?.items.lazy.map(Buddy.init)
			.reduce(into: [:]) { $0[$1.level, default: []].append($1.instance) }
			?? [:]
		
		assert(purchasedAgents.intersection(Self.starterAgents).isEmpty)
		agents = purchasedAgents.union(Self.starterAgents)
	}
	
	public func owns<Item: InventoryItem>(_ itemID: Item.ID) -> Bool {
		self[keyPath: Item.ownedItems].contains(itemID)
	}
	 
	private struct Buddy {
		var level: Weapon.Buddy.Level.ID
		var instance: Weapon.Buddy.Instance.ID
		
		init(_ item: ItemCollection.Item) {
			level = .init(rawID: item.id)
			instance = .init(rawID: item.instanceID!)
		}
	}
}

public protocol InventoryItem {
	associatedtype OwnedItems: Collection<ID>
	typealias ID = ObjectID<Self, LowercaseUUID>
	
	static var ownedItems: KeyPath<Inventory, OwnedItems> { get }
	static var typeID: ItemType.ID { get }
}

extension Agent: InventoryItem {
	public static let ownedItems = \Inventory.agents
	public static let typeID = ItemType.ID.agents
}

extension PlayerCard: InventoryItem {
	public static let ownedItems = \Inventory.cards
	public static let typeID = ItemType.ID.cards
}

extension PlayerTitle: InventoryItem {
	public static let ownedItems = \Inventory.titles
	public static let typeID = ItemType.ID.titles
}

extension Weapon.Skin.Level: InventoryItem {
	public static let ownedItems = \Inventory.skinLevels
	public static let typeID = ItemType.ID.skinLevels
}

extension Weapon.Skin.Chroma: InventoryItem {
	public static let ownedItems = \Inventory.skinChromas
	public static let typeID = ItemType.ID.skinChromas
}

extension Spray: InventoryItem {
	public static let ownedItems = \Inventory.sprays
	public static let typeID = ItemType.ID.sprays
}

extension Weapon.Buddy.Level: InventoryItem {
	public static let ownedItems = \Inventory.buddies.keys
	public static let typeID = ItemType.ID.buddies
}

/// agent, card, title, etc.
public enum ItemType {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public extension ItemType.ID {
	static let agents = Self("01bb38e1-da47-4e6a-9b3d-945fe4655707")!
	static let cards = Self("3f296c07-64c3-494c-923b-fe692a4fa1bd")!
	static let titles = Self("de7caa6b-adf7-4588-bbd1-143831e786c6")!
	static let skinLevels = Self("e7c63390-eda7-46e0-bb7a-a6abdacd2433")!
	static let skinChromas = Self("3ad1b2b2-acdb-4524-852f-954a76ddae0a")!
	static let sprays = Self("d5f120f8-ff8c-4aac-92ea-f2b5acbe9475")!
	static let contracts = Self("f85cb6f7-33e5-4dc8-b609-ec7212301948")!
	static let buddies = Self("dd3bf334-87f3-40bd-b043-682a57a8dc3a")!
}

struct APIInventory: Decodable {
	fileprivate var collectionsByType: [ItemCollection]
	
	private enum CodingKeys: String, CodingKey {
		case collectionsByType = "EntitlementsByTypes"
	}
}

private struct ItemCollection: Decodable {
	var id: ItemType.ID
	var items: [Item]
	
	private enum CodingKeys: String, CodingKey {
		case id = "ItemTypeID"
		case items = "Entitlements"
	}
	
	struct Item: Decodable {
		var id: LowercaseUUID
		var instanceID: LowercaseUUID?
		
		private enum CodingKeys: String, CodingKey {
			case id = "ItemID"
			case instanceID = "InstanceID"
		}
	}
}
