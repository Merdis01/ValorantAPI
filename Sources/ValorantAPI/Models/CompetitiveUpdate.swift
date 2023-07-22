import Foundation
import ErgonomicCodable

public struct CompetitiveUpdate: Codable, Identifiable {
	public var id: Match.ID
	@SpecialOptional(.emptyString)
	public var mapID: MapID?
	public var startTime: Date
	public var tierBeforeUpdate: Int
	public var tierAfterUpdate: Int
	public var tierProgressBeforeUpdate: Int
	public var tierProgressAfterUpdate: Int
	public var ratingEarned: Int
	public var performanceBonus: Int
	public var afkPenalty: Int
	
	public var isRanked: Bool { tierAfterUpdate != 0 }
	public var isDodge: Bool { mapID == nil }
	
	/// - note: "elo" values are wrong for immortal+ in episode 2 and later, where they were changed so tier progress is relative to immortal 1 rather than each individual rank, but still useful.
	public var eloChange: Int { eloAfterUpdate - eloBeforeUpdate }
	/// - note: "elo" values are wrong for immortal+ in episode 2 and later, where they were changed so tier progress is relative to immortal 1 rather than each individual rank, but still useful.
	public var eloBeforeUpdate: Int { tierBeforeUpdate * 100 + tierProgressBeforeUpdate }
	/// - note: "elo" values are wrong for immortal+ in episode 2 and later, where they were changed so tier progress is relative to immortal 1 rather than each individual rank, but still useful.
	public var eloAfterUpdate: Int { tierAfterUpdate * 100 + tierProgressAfterUpdate }
	
	public init(
		id: Match.ID,
		mapID: MapID?,
		startTime: Date,
		tierBeforeUpdate: Int = 0,
		tierAfterUpdate: Int = 0,
		tierProgressBeforeUpdate: Int = 0,
		tierProgressAfterUpdate: Int = 0,
		ratingEarned: Int = 0,
		performanceBonus: Int = 0,
		afkPenalty: Int = 0
	) {
		self.id = id
		self._mapID = .init(wrappedValue: mapID)
		self.startTime = startTime
		self.tierBeforeUpdate = tierBeforeUpdate
		self.tierAfterUpdate = tierAfterUpdate
		self.tierProgressBeforeUpdate = tierProgressBeforeUpdate
		self.tierProgressAfterUpdate = tierProgressAfterUpdate
		self.ratingEarned = ratingEarned
		self.performanceBonus = performanceBonus
		self.afkPenalty = afkPenalty
	}
	
	public func isContiguous(from previous: Self) -> Bool {
		assert(startTime > previous.startTime)
		return tierBeforeUpdate == previous.tierAfterUpdate
		&& tierProgressBeforeUpdate == previous.tierProgressAfterUpdate
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "MatchID"
		case mapID = "MapID"
		case startTime = "MatchStartTime"
		case tierAfterUpdate = "TierAfterUpdate"
		case tierBeforeUpdate = "TierBeforeUpdate"
		case tierProgressAfterUpdate = "RankedRatingAfterUpdate"
		case tierProgressBeforeUpdate = "RankedRatingBeforeUpdate"
		case ratingEarned = "RankedRatingEarned"
		case performanceBonus = "RankedRatingPerformanceBonus"
		case afkPenalty = "AFKPenalty"
	}
}
