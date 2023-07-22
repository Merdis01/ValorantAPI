import Foundation

/// Represents the concept of a user, separate from the auth-provided `UserInfo` or the in-match `Player`.
public struct User: Codable, Identifiable {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public var id: ID
	public var gameName: String
	public var tagLine: String
	
	public var name: String {
		"\(gameName) #\(tagLine)"
	}
	
	public init(id: ID, gameName: String, tagLine: String) {
		self.id = id
		self.gameName = gameName
		self.tagLine = tagLine
	}
	
	public init(_ player: Player) {
		self.id = player.id
		self.gameName = player.gameName
		self.tagLine = player.tagLine
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "Subject"
		case gameName = "GameName"
		case tagLine = "TagLine"
	}
}
