import Foundation
import Protoquest

/// An error received from Riot's API.
public enum APIError: Error {
	/// This is outputted for 401 error codes, which the API sometimes responds with instead of providing actual error information… It usually also means you need to reauthenticate.
	case unauthorized
	/// This likely means your access token has expired.
	case tokenFailure(message: String)
	/// The session has expired or otherwise been invalidated. You'll need to reauthenticate.
	/// - Parameter mfaRequired: true if the session tried to reauth but failed due to an MFA code being required.
	case sessionExpired(mfaRequired: Bool)
	/// The session could not be resumed, though it was not recognized as clearly being expired—it's possible Riot's API has changed and this code no longer works with it. Reauthenticating could still fix it though!
	case sessionResumptionFailure(Error)
	/// The service is currently down for scheduled maintenance.
	case scheduledDowntime(message: String)
	/// The API could not find a resource at the given location—likely code 404, though we only check the associated ``RiotError/errorCode``.
	case resourceNotFound
	/// A non-200 response code was received. If the API returned a valid error JSON, the provided error is passed on here.
	case badResponseCode(Int, Protoresponse, RiotError?)
	/// You were rate-limited for sending too many requests. If provided, `retryAfter` indicates after how many seconds the limit should be lifted again.
	case rateLimited(retryAfter: Int?)
	
	public var recommendsReauthentication: Bool {
		switch self {
		case .unauthorized, .tokenFailure, .sessionExpired, .sessionResumptionFailure:
			return true
		case .scheduledDowntime, .resourceNotFound, .badResponseCode, .rateLimited:
			return false
		}
	}
}

/// How Riot's API represents an error it encountered.
public struct RiotError: Decodable {
	/// A programmer-facing representation of the error that occurred, in `SCREAMING_SNAKE_CASE`.
	public var errorCode: String
	/// A human-readable description of the error.
	public var message: String
}

extension APIError {
	init(statusCode: Int, response: Protoresponse) {
		if let error = try? response.decodeJSON(as: RiotError.self) {
			switch error.errorCode {
			case "BAD_CLAIMS":
				self = .tokenFailure(message: error.message)
			case "SCHEDULED_DOWNTIME":
				self = .scheduledDowntime(message: error.message)
			case "RESOURCE_NOT_FOUND":
				self = .resourceNotFound
			default:
				self = .badResponseCode(statusCode, response, error)
			}
		} else {
			switch statusCode {
			case 401:
				self = .unauthorized
			case 429:
				self = .rateLimited(
					retryAfter: response.httpMetadata!
						.value(forHTTPHeaderField: "Retry-After")
						.flatMap(Int.init)
				)
			default:
				self = .badResponseCode(statusCode, response, nil)
			}
		}
	}
}
