import Foundation

public typealias SimpleRawWrapper = _RawWrapper & Hashable & Codable

public protocol _RawWrapper: RawRepresentable {
	init(_ rawValue: RawValue)
}

public extension _RawWrapper {
	init?(rawValue: RawValue) {
		self.init(rawValue)
	}
}

extension _RawWrapper where RawValue: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.init(try container.decode(RawValue.self))
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}
