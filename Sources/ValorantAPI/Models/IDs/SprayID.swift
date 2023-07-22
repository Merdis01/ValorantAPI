import Foundation

public enum Spray {
	public typealias ID = ObjectID<Self, LowercaseUUID>
	
	public enum Slot {
		public typealias ID = ObjectID<Self, LowercaseUUID>
	}
}

public extension Spray.Slot.ID {
	static let right = Self("5863985e-43ac-b05d-cb2d-139e72970014")!
	static let top = Self("7cdc908e-4f69-9140-a604-899bd879eed1")!
	static let left = Self("0814b2fe-4512-60a4-5288-1fbdcec6ca48")!
	static let bottom = Self("04af080a-4071-487b-61c0-5b9c0cfaac74")!
	
	/// lists all 4 slots in counterclockwise order, starting from the right one (angle 0° by convention)
	static let inCCWOrder = [right, top, left, bottom]
}
