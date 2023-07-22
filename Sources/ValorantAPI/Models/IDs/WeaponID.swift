import Foundation

public enum Weapon {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public enum Skin {
		public typealias ID = ObjectID<Self, LowercaseUUID>
		
		public enum Level {
			public typealias ID = ObjectID<Self, LowercaseUUID>
		}
		
		public enum Chroma {
			public typealias ID = ObjectID<Self, LowercaseUUID>
		}
	}
	
	public enum Buddy {
		public typealias ID = ObjectID<Self, LowercaseUUID>
		
		public enum Level {
			public typealias ID = ObjectID<Self, LowercaseUUID>
		}
		
		public enum Instance {
			public typealias ID = ObjectID<Self, LowercaseUUID>
		}
	}
}

public extension Weapon.ID {
	static let melee = Self("2f59173c-4bed-b6c3-2191-dea9b58be9c7")!
	static let classic = Self("29a0cfab-485b-f5d5-779a-b59f85e204a8")!
	static let shorty = Self("42da8ccc-40d5-affc-beec-15aa47b42eda")!
	static let frenzy = Self("44d4e95c-4157-0037-81b2-17841bf2e8e3")!
	static let ghost = Self("1baa85b4-4c70-1284-64bb-6481dfc3bb4e")!
	static let sheriff = Self("e336c6b8-418d-9340-d77f-7a9e4cfe0702")!
	static let stinger = Self("f7e1b454-4ad4-1063-ec0a-159e56b58941")!
	static let spectre = Self("462080d1-4035-2937-7c09-27aa2a5c27a7")!
	static let bucky = Self("910be174-449b-c412-ab22-d0873436b21b")!
	static let judge = Self("ec845bf4-4f79-ddda-a3da-0db3774b2794")!
	static let bulldog = Self("ae3de142-4d85-2547-dd26-4e90bed35cf7")!
	static let guardian = Self("4ade7faa-4cf1-8376-95ef-39884480959b")!
	static let phantom = Self("ee8e8d15-496b-07ac-e5f6-8fae5d4c7b1a")!
	static let vandal = Self("9c82e19d-4575-0200-1a81-3eacf00cf872")!
	static let marshal = Self("c4883e50-4494-202c-3ec3-6b8a9284f00b")!
	static let `operator` = Self("a03b24d3-4319-996d-0f8c-94bbfba1dfc7")!
	static let ares = Self("55d8a0f4-4274-ca67-fe2c-06ab45efdf58")!
	static let odin = Self("63e6c2b6-4a8e-869c-3d4c-e38355226584")!
	
	static let orderInShop = [
		classic,
		shorty,
		frenzy,
		ghost,
		sheriff,
		stinger,
		spectre,
		bucky,
		judge,
		bulldog,
		guardian,
		phantom,
		vandal,
		marshal,
		`operator`,
		ares,
		odin,
	]
	
	static let orderInCollection = orderInShop + [melee]
}
