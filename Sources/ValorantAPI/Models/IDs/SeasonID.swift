import Foundation

public enum Season {
	public typealias ID = ObjectID<Self, LowercaseUUID>
}

public extension Season.ID {
	static let closedBeta = Self("0df5adb9-4dcb-6899-1306-3e9860661dd3")!
	static let episode1 = Self("fcf2c8f4-4324-e50b-2e23-718e4a3ab046")!
	static let episode1Act1 = Self("3f61c772-4560-cd3f-5d3f-a7ab5abda6b3")!
	static let episode1Act2 = Self("0530b9c4-4980-f2ee-df5d-09864cd00542")!
	static let episode1Act3 = Self("46ea6166-4573-1128-9cea-60a15640059b")!
	static let episode2 = Self("71c81c67-4fae-ceb1-844c-aab2bb8710fa")!
	static let episode2Act1 = Self("97b6e739-44cc-ffa7-49ad-398ba502ceb0")!
	static let episode2Act2 = Self("ab57ef51-4e59-da91-cc8d-51a5a2b9b8ff")!
	static let episode2Act3 = Self("52e9749a-429b-7060-99fe-4595426a0cf7")!
	static let episode3 = Self("97b39124-46ce-8b55-8fd1-7cbf7ffe173f")!
	static let episode3Act1 = Self("2a27e5d2-4d30-c9e2-b15a-93b8909a442c")!
	static let episode3Act2 = Self("4cb622e1-4244-6da3-7276-8daaf1c01be2")!
	static let episode3Act3 = Self("a16955a5-4ad0-f761-5e9e-389df1c892fb")!
	static let episode4 = Self("808202d6-4f2b-a8ff-1feb-b3a0590ad79f")!
	static let episode4Act1 = Self("573f53ac-41a5-3a7d-d9ce-d6a6298e5704")!
	static let episode4Act2 = Self("d929bc38-4ab6-7da4-94f0-ee84f8ac141e")!
	static let episode4Act3 = Self("3e47230a-463c-a301-eb7d-67bb60357d4f")!
	static let episode5 = Self("79f9d00f-433a-85d6-dfc3-60aef115e699")!
	static let episode5Act1 = Self("67e373c7-48f7-b422-641b-079ace30b427")!
	static let episode5Act2 = Self("7a85de9a-4032-61a9-61d8-f4aa2b4a84b6")!
	static let episode5Act3 = Self("aca29595-40e4-01f5-3f35-b1b3d304c96e")!
	
	/// Useful for comparing ranks across seasons, since the addition of the ascendant rank shifted immortal and radiant's tier numbers up by 3.
	static let seasonsBeforeAscendantRank: Set<Self> = [
		closedBeta,
		episode1, episode1Act1, episode1Act2, episode1Act3,
		episode2, episode2Act1, episode2Act2, episode2Act3,
		episode3, episode3Act1, episode3Act2, episode3Act3,
		episode4, episode4Act1, episode4Act2, episode4Act3,
	]
	
	var wasBeforeAscendantRank: Bool {
		Self.seasonsBeforeAscendantRank.contains(self)
	}
}
