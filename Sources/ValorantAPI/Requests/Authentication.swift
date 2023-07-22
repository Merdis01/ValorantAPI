import Foundation
import HandyOperators
import Protoquest

extension AuthClient {
	func getAccessToken(
		loginBehavior: LoginBehavior
	) async throws -> AccessToken {
		let cookiesResponse = try await send(CookiesRequest())
		let response: AuthResponse
		switch cookiesResponse.type {
		case .auth:
			guard case .allow(let credentials, _) = loginBehavior else {
				throw APIError.sessionExpired(mfaRequired: false)
			}
			
			if let error = cookiesResponse.error {
				print("error establishing session; discarding cookies:", error)
				clearCookies()
				_ = try await send(CookiesRequest())
			}
			response = try await send(CredentialsAuthRequest(
				username: credentials.username,
				password: credentials.password
			))
		default:
			response = cookiesResponse
		}
		
		return try await handleAuthResponse(response, loginBehavior: loginBehavior)
	}
	
	func getUserID() async throws -> User.ID {
		try await send(UserInfoRequest()).sub
	}
	
	func getLocation(using token: AccessToken) async throws -> Location {
		let pasInfo = try await send(PASRequest(idToken: token.idToken))
		let region = pasInfo.affinities.live
		return try Location.location(forRegion: region)
		??? AuthHandlingError.unknownRegion(region)
	}
	
	private func handleAuthResponse(
		_ response: AuthResponse,
		loginBehavior: LoginBehavior
	) async throws -> AccessToken {
		switch response.type {
		case .auth:
			throw AuthenticationError(message: response.error ?? "<no message given>")
		case .error:
			throw AuthHandlingError.unexpectedError(response.error)
		case .multifactor:
			guard case .allow(_, let multifactorHandler) = loginBehavior else {
				throw APIError.sessionExpired(mfaRequired: false)
			}
			// error is "multifactor_attempt_failed" if incorrect code given
			guard let info = response.multifactor
			else { throw AuthHandlingError.missingResponseBody }
			let code = try await multifactorHandler(info)
			let newResponse = try await send(MultifactorAuthRequest(
				code: code, rememberDevice: true
			))
			return try await handleAuthResponse(newResponse, loginBehavior: loginBehavior)
		case .response:
			assert(response.error == nil)
			guard let body = response.response
			else { throw AuthHandlingError.missingResponseBody }
			return body.extractAccessToken()
		}
	}
	
	/// specifies how to behave in case there is no valid session and a login is required
	enum LoginBehavior {
		case disallow // only allow resumption
		case allow(Credentials, MultifactorHandler)
	}
}

private enum AuthHandlingError: Error, LocalizedError {
	case missingResponseBody
	case invalidTokenURL(URL)
	case unexpectedError(String?)
	case missingRedirectURL(response: String)
	case unknownRegion(String)
	case sessionEstablishmentFailed(AuthResponse)
	
	var errorDescription: String? {
		switch self {
		case .missingResponseBody:
			return "[Auth] Missing Response Body"
		case .invalidTokenURL(let url):
			return "[Auth] Invalid Token URL (don't share this publicly!): \(url)"
		case .unexpectedError(let error):
			return "[Auth] Unexpected Error: \(error ?? "<no message>")"
		case .missingRedirectURL(let response):
			return "[Auth] Missing Redirect URL: \(response)"
		case .unknownRegion(let region):
			return "[Auth] Unknown Region: \(region)"
		case .sessionEstablishmentFailed(let response):
			return "[Auth] Could not establish session: \(response)"
		}
	}
}

public struct AuthenticationError: LocalizedError {
	static var messageOverrides = [
		"auth_failure": "Invalid username or password."
	]
	
	public var message: String
	
	public var errorDescription: String? {
		Self.messageOverrides[message] ?? message
	}
}

private struct CookiesRequest: JSONJSONRequest, Encodable, AuthRequest {
	typealias Response = AuthResponse
	
	var path: String { "api/v1/authorization" }
	
	let clientID = "play-valorant-web-prod"
	let responseType = "token id_token"
	let redirectURI = "https://playvalorant.com/"
	let nonce = 1 // TODO: this feels wrong, not sure what the nonce would be for though
	let scope = "account openid"
}

private protocol AuthMessage: JSONJSONRequest, Encodable, AuthRequest
where Response == AuthResponse {
	var type: AuthMessageType { get }
}

extension AuthMessage {
	var httpMethod: String { "PUT" }
	var path: String { "api/v1/authorization" }
}

private struct CredentialsAuthRequest: AuthMessage {
	let type = AuthMessageType.auth
	let username, password: String
	var remember = true
}

private struct MultifactorAuthRequest: AuthMessage {
	var encoderOverride: JSONEncoder? { .init() } // no snake case conversion for this for some reason lol
	
	let type = AuthMessageType.multifactor
	let code: String
	let rememberDevice: Bool
}

private struct AuthResponse: Decodable {
	var type: AuthMessageType
	
	var error: String?
	var response: AccessTokenInfo?
	var multifactor: MultifactorInfo?
	
	struct AccessTokenInfo: Decodable {
		var mode: String // fragment
		var parameters: Parameters
		
		func extractAccessToken() -> AccessToken {
			assert(mode == "fragment")
			return parameters.uri.extractAccessToken()!
		}
		
		struct Parameters: Decodable {
			var uri: URL
		}
	}
}

public struct Credentials: Hashable, Codable {
	public var username: String
	public var password: String
	
	public init(username: String = "", password: String = "") {
		self.username = username
		self.password = password
	}
}

public typealias MultifactorHandler = (MultifactorInfo) async throws -> String
public struct MultifactorInfo: Decodable, Hashable {
	public var version: String
	public var codeLength: Int
	/// the method the server has chosen (currently always expected to be email)
	public var method: String
	/// other methods that are available (no way to select them currently)
	public var methods: [String]
	/// the email the code was sent to; mostly blanked-out
	public var email: String
	
	public static func mocked(codeLength: Int, email: String) -> Self {
		.init(
			version: "v2",
			codeLength: codeLength,
			method: "email",
			methods: ["email"],
			email: email
		)
	}
	
	private enum CodingKeys: String, CodingKey {
		case version = "mfaVersion"
		case codeLength = "multiFactorCodeLength"
		case method, methods
		case email
	}
}

private struct UserInfoRequest: GetJSONRequest, AuthRequest {
	var path: String { "userinfo" }
	
	struct Response: Decodable {
		var sub: User.ID
	}
}

private struct PASRequest: JSONJSONRequest, Encodable, AuthRequest {
	var baseURLOverride: URL? {
		.init(string: "https://riot-geo.pas.si.riotgames.com")!
	}
	
	var httpMethod: String { "PUT" }
	var path: String { "pas/v1/product/valorant" }
	
	var idToken: String
	
	struct Response: Decodable {
		var token: String
		var affinities: Affinities
		
		struct Affinities: Decodable {
			var live: String
		}
	}
}

extension URL {
	func collectQueryItems() -> [String: String] {
		.init(
			uniqueKeysWithValues: URLComponents(url: self, resolvingAgainstBaseURL: false)!
				.fragment!
				.split(separator: "&")
				.map {
					let parts = $0.components(separatedBy: "=")
					assert(parts.count == 2)
					return (parts.first!, parts.last!)
				}
		)
	}
	
	func extractAccessToken() -> AccessToken? {
		let values = collectQueryItems()
		guard
			let type = values["token_type"],
			let token = values["access_token"],
			let idToken = values["id_token"],
			let duration = values["expires_in"].flatMap(Int.init)
		else { return nil }
		return .init(
			type: type,
			token: token,
			idToken: idToken,
			expiration: .init(timeIntervalSinceNow: .init(duration) - 30) // 30s tolerance to make sure we don't try to use an expired token
		)
	}
}

private enum AuthMessageType: String, Hashable, Codable {
	case auth
	case response
	case error
	case multifactor
}
