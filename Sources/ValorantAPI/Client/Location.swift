import Foundation

public struct Location: Hashable, Codable {
	public static let europe = Self(region: "eu", shard: "eu")
	public static let northAmerica = Self(region: "na", shard: "na")
	public static let latinAmerica = Self(region: "latam", shard: "na")
	public static let brazil = Self(region: "br", shard: "na")
	public static let korea = Self(region: "kr", shard: "kr")
	public static let asiaPacific = Self(region: "ap", shard: "ap")
	public static let pbe = Self(region: "na", shard: "pbe")
	
	public static let all = [europe, northAmerica, latinAmerica, brazil, korea, asiaPacific, pbe]
	
	public var region: String
	public var shard: String
	
	public init(region: String, shard: String) {
		self.region = region
		self.shard = shard
	}
	
	public static func location(forRegion region: String) -> Location? {
		all.first { $0.region == region }
	}
}
