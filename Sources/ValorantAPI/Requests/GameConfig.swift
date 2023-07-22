import Foundation
import Protoquest
import HandyOperators

extension ValorantClient {
	/// Fetches Riot's configuration for clients in the specified location.
	public func getGameConfig() async throws -> GameConfig {
		let response = try await send(GameConfigRequest())
		return try .init(reading: response)
	}
}

private struct GameConfigRequest: GetJSONRequest, ValorantRequest {
	func baseURL(for location: Location) -> URL {
		.init(string: "https://shared.\(location.shard).a.pvp.net/v1/config/\(location.region)")!
	}
	
	struct Response: Decodable {
		var lastApplication: Date
		var collapsed: [String: String] // yeah, it's all strings
		
		enum CodingKeys: String, CodingKey {
			case lastApplication = "LastApplication"
			case collapsed = "Collapsed"
		}
		
		func string(forKey key: String) throws -> String {
			try collapsed[key] ??? ReadingError.missingEntry(key: key)
		}
		
		func int(forKey key: String) throws -> Int {
			let raw = try string(forKey: key)
			return try Int(raw) ??? ReadingError.invalidValue(key: key, value: raw)
		}
		
		private enum ReadingError: Error {
			case missingEntry(key: String)
			case invalidValue(key: String, value: String)
		}
	}
}

public struct GameConfig: Codable {
	/// Ranked season resets (and patches) are staggered across the locations—this is the amount by which the current location is offset from the theoretical reset time.
	public var seasonOffset: TimeInterval
}

private extension GameConfig {
	init(reading response: GameConfigRequest.Response) throws {
		seasonOffset = .init(try response.int(forKey: "competitiveSeasonOffsetEndTime"))
	}
}
