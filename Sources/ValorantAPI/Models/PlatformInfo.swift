import Foundation

public struct PlatformInfo: Codable {
	static let supportedExample = Self(
		type: "PC",
		os: "Windows",
		osVersion: "10.0.19042.1.256.64bit",
		chipset: "Unknown"
	)
	
	public var type: String
	public var os: String
	public var osVersion: String
	public var chipset: String
	
	private enum CodingKeys: String, CodingKey {
		case type = "platformType"
		case os = "platformOS"
		case osVersion = "platformOSVersion"
		case chipset = "platformChipset"
	}
}
