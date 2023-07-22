import Foundation
import HandyOperators

public struct MapID: SimpleRawWrapper {
	public static let knownMaps = knownStandardMaps + [.range]
	public static let knownStandardMaps: [Self] = [
		.split,
		.haven,
		.bind,
		.ascent,
		.icebox,
		.breeze,
		.fracture,
	]
	
	public static let split = mapID("Bonsai")
	public static let haven = mapID("Triad")
	public static let bind = mapID("Duality")
	public static let ascent = mapID("Ascent")
	public static let icebox = mapID("Port")
	public static let breeze = mapID("Foxtrot")
	public static let fracture = mapID("Canyon")
	public static let range = mapID("Range", group: "Poveglia")
	
	private static func mapID(_ key: String, group: String? = nil) -> Self {
		Self("/Game/Maps/\(group ?? key)/\(key)")
	}
	
	public var rawValue: String
	
	public init(_ rawValue: String) {
		self.rawValue = rawValue
	}
}
