import Foundation

public enum ProvisioningFlow {
	public typealias ID = ObjectID<Self, String>
}

public extension ProvisioningFlow.ID {
	static let matchmaking = Self(rawID: "Matchmaking")
	static let customGame = Self(rawID: "CustomGame")
	static let shootingRange = Self(rawID: "ShootingRange")
}
