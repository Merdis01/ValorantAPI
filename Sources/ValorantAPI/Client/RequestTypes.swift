import Foundation
import Protoquest
import HandyOperators

extension ValorantClient {
	static let requestEncoder = JSONEncoder()
	
	/// The decoder used to decode JSON data received from Riot's servers.
	/// Exposed for conveniently mocking preview data by decoding JSONs from the api
	public static let responseDecoder = JSONDecoder() <- {
		$0.dateDecodingStrategy = .iso8601OrTimestamp
		$0.userInfo[.isDecodingFromRiot] = true
	}
}

protocol ValorantRequest: Request {
	func baseURL(for location: Location) -> URL
}

extension ValorantRequest {
	func urlRequest(for location: Location) throws -> URLRequest {
		try .init(url: url(relativeTo: baseURL(for: location))) <- configure(_:)
	}
}

extension JSONEncodingRequest where Self: ValorantRequest {
	var encoderOverride: JSONEncoder? { ValorantClient.requestEncoder }
}

extension JSONDecodingRequest where Self: ValorantRequest {
	var decoderOverride: JSONDecoder? { ValorantClient.responseDecoder }
}

protocol GameDataRequest: ValorantRequest {}

extension GameDataRequest {
	func baseURL(for location: Location) -> URL {
		BaseURLs.gameAPI(location: location)
	}
}

enum BaseURLs {
	static let authAPI = URL(string: "https://auth.riotgames.com")!
	static let entitlementsAPI = URL(string: "https://entitlements.auth.riotgames.com/api")!
	
	static func gameAPI(location: Location) -> URL {
		URL(string: "https://pd.\(location.shard).a.pvp.net")!
	}
	
	static func liveGameAPI(location: Location) -> URL {
		URL(string: "https://glz-\(location.region)-1.\(location.shard).a.pvp.net")!
	}
}

extension Decoder {
	var isDecodingFromRiot: Bool {
		(userInfo[.isDecodingFromRiot] as? Bool) ?? false
	}
}

private extension CodingUserInfoKey {
	static var isDecodingFromRiot = Self(rawValue: "isDecodingFromRiot")!
}

private extension JSONDecoder.DateDecodingStrategy {
	static let iso8601OrTimestamp = custom { decoder in
		let container = try decoder.singleValueContainer()
		return try nil
		// unix timestamp
		?? (try? Date(timeIntervalSince1970: container.decode(TimeInterval.self) / 1000))
		// ISO-8601 date string
		?? (try? container.decode(String.self)).flatMap { string in
			formatters.compactMap { $0.date(from: string) }.first
		}
		// failed
		??? DecodingError.dataCorruptedError(
			in: container,
			debugDescription: "Could not decode timestamp nor ISO-8601 date from value."
		)
	}
	
	// this would not be necessary if the formatter were lenient in its parsing, but nooo…
	private static let formatters: [ISO8601DateFormatter] = [
		ISO8601DateFormatter() <- { $0.formatOptions = [.withInternetDateTime] },
		ISO8601DateFormatter() <- { $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds] },
	]
}
