import XCTest
import Protoquest
import HandyOperators
@testable import ValorantAPI

final class ValorantAPITests: XCTestCase {
	static let playerID = Player.ID("3fa8598d-066e-5bdb-998c-74c015c5dba5")!
	static let liveMatchID = Match.ID("a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")!
	static let sovaID = Agent.ID("320b2a48-4d9b-a075-30f1-1f93a9b638fa")!
	static let reynaID = Agent.ID("a3bfb853-43b2-7238-a4f1-ad90e9e46bcc")!
	static let partyID = Party.ID("57837ba2-675f-4c5f-955a-11f4ab040795")!
	
	func testAuthentication() async throws {
		try await testCommunication {
			_ = try await APISession(
				credentials: .init(username: "username", password: "password"),
				urlSessionOverride: makeSession(),
				multifactorHandler: { _ in fatalError() }
			)
		} expecting: {
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.post()
				.responseBody(#"{ "type": "auth", "country": "che" }"#)
			
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.put()
				.responseBody(fileNamed: "responses/access_token")
			
			ExpectedRequest.Group {
				ExpectedRequest(to: "https://entitlements.auth.riotgames.com/api/token/v1")
					.post()
					.responseBody(#"{ "entitlements_token": "ENTITLEMENTS_TOKEN" }"#)
				
				ExpectedRequest(to: "https://auth.riotgames.com/userinfo")
					.responseBody(#"{ "sub": "3fa8598d-066e-5bdb-998c-74c015c5dba5" }"#)
				
				ExpectedRequest(to: "https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant")
					.put()
					.responseBody(#"{ "affinities": { "live": "eu" }, "token": "" }"#)
			}
		}
	}
	
	func testMultifactor() async throws {
		try await testCommunication {
			_ = try await APISession(
				credentials: .init(username: "username", password: "password"),
				urlSessionOverride: makeSession(),
				multifactorHandler: { info in
					XCTAssertEqual(info, .init(version: "v2", codeLength: 6, method: "email", methods: ["email"], email: "jul**@****.com"))
					return "123456"
				}
			)
		} expecting: {
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.post()
				.responseBody(#"{ "type": "auth", "country": "che" }"#)
			
			// credentials accepted; must provide 2FA code
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.put()
				.responseBody(fileNamed: "responses/multifactor")
			
			// retry
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.put()
				.responseBody(fileNamed: "responses/multifactor")
			
			// correct now
			ExpectedRequest(to: "https://auth.riotgames.com/api/v1/authorization")
				.put()
				.responseBody(fileNamed: "responses/access_token")
			
			ExpectedRequest.Group {
				ExpectedRequest(to: "https://entitlements.auth.riotgames.com/api/token/v1")
					.post()
					.responseBody(#"{ "entitlements_token": "ENTITLEMENTS_TOKEN" }"#)
				
				ExpectedRequest(to: "https://auth.riotgames.com/userinfo")
					.responseBody(#"{ "sub": "3fa8598d-066e-5bdb-998c-74c015c5dba5" }"#)
				
				ExpectedRequest(to: "https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant")
					.put()
					.responseBody(#"{ "affinities": { "live": "eu" }, "token": "" }"#)
			}
		}
	}
	
	private func makeSession() -> URLSession {
		verifyingURLSession() <- {
			$0.configuration.httpCookieStorage!.setCookie(.init(properties: [
				.name: "ssid",
				.value: "SESSION_ID",
				.domain: "auth.riotgames.com",
				.path: "/",
			])!)
			$0.configuration.httpCookieStorage!.setCookie(.init(properties: [
				.name: "tdid",
				.value: "TDID",
				.domain: "auth.riotgames.com",
				.path: "/",
			])!)
		}
	}
	
	func testLiveNoGame() async throws {
		let client = mockClient()
		
		try await testCommunication {
			let matchID = try await client.getLiveMatch(inPregame: true)
			XCTAssertNil(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseCode(404)
				.responseBody(fileNamed: "responses/resource_not_found")
		}
	}
	
	func testLivePregame() async throws {
		let client = mockClient()
		
		let matchID = try await testCommunication {
			try await client.getLiveMatch(inPregame: true)!
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseBody(fileNamed: "responses/live_player_info")
		}
		XCTAssertEqual(matchID, Self.liveMatchID)
		
		let matchInfo = try await testCommunication {
			try await client.getLivePregameInfo(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")
				.responseBody(fileNamed: "pregame_match")
		}
		
		XCTAssertEqual(matchInfo.id, matchID)
		XCTAssert(matchInfo.team.players.map(\.id).contains(Self.playerID))
	}
	
	func testLiveGame() async throws {
		let client = mockClient()
		
		let matchID = try await testCommunication {
			try await client.getLiveMatch(inPregame: false)!
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/core-game/v1/players/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseBody(fileNamed: "responses/live_player_info")
		}
		XCTAssertEqual(matchID, Self.liveMatchID)
		
		let matchInfo = try await testCommunication {
			try await client.getLiveGameInfo(matchID)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/core-game/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1")
				.responseBody(fileNamed: "live_match")
		}
		
		XCTAssertEqual(matchInfo.id, matchID)
		XCTAssert(matchInfo.players.map(\.id).contains(Self.playerID))
	}
	
	func testPicking() async throws {
		let client = mockClient()
		
		try await testCommunication {
			let updatedInfo = try await client.selectAgent(Self.sovaID, in: Self.liveMatchID)
			let player = updatedInfo.team.players.first { $0.id == Self.playerID }!
			XCTAssertEqual(player.agentID, Self.sovaID)
			XCTAssertEqual(player.agentSelectionState, .selected)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1/select/320b2a48-4d9b-a075-30f1-1f93a9b638fa")
				.post()
				.responseBody(fileNamed: "responses/live_select_sova")
		}
		
		try await testCommunication {
			let updatedInfo = try await client.lockInAgent(Self.reynaID, in: Self.liveMatchID)
			let player = updatedInfo.team.players.first { $0.id == Self.playerID }!
			XCTAssertEqual(player.agentID, Self.reynaID)
			XCTAssertEqual(player.agentSelectionState, .locked)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/pregame/v1/matches/a6e7cba8-a4ef-4aae-b775-4eb61e43a0d1/lock/a3bfb853-43b2-7238-a4f1-ad90e9e46bcc")
				.post()
				.responseBody(fileNamed: "responses/live_lock_reyna")
		}
	}
	
	func testInventory() async throws {
		let client = mockClient()
		
		try await testCommunication {
			let inventory = try await client.getInventory()
			XCTAssertEqual(inventory.agents.count, 19)
		} expecting: {
			ExpectedRequest(to: "https://pd.eu.a.pvp.net/store/v1/entitlements/3fa8598d-066e-5bdb-998c-74c015c5dba5")
				.responseBody(fileNamed: "inventory")
		}
	}
	
	func testGetUsers() async throws {
		let client = mockClient()
		
		try await testCommunication {
			let users = try await client.getUsers(for: [Self.playerID])
			XCTAssertEqual(users.count, 1)
			XCTAssertEqual(users.first?.id, Self.playerID)
		} expecting: {
			ExpectedRequest(to: "https://pd.eu.a.pvp.net/name-service/v2/players")
				.put()
				.requestBody(#"["3fa8598d-066e-5bdb-998c-74c015c5dba5"]"#)
				.responseBody(fileNamed: "responses/users")
		}
	}
	
	func testQueueSelection() async throws {
		let client = mockClient()
		
		try await testCommunication {
			let party = try await client.changeQueue(to: .unrated, in: Self.partyID)
			XCTAssertEqual(party.matchmakingData.queueID, .unrated)
		} expecting: {
			ExpectedRequest(to: "https://glz-eu-1.eu.a.pvp.net/parties/v1/parties/57837ba2-675f-4c5f-955a-11f4ab040795/queue")
				.requestBody(#"{"queueID":"unrated"}"#)
				.post()
				.responseBody(fileNamed: "party")
		}
	}
	
	func mockClient() -> ValorantClient {
		.init(
			session: .init(
				credentials: .init(),
				accessToken: .init(type: "Bearer", token: "ACCESS_TOKEN", idToken: "ID_TOKEN", expiration: .distantFuture),
				entitlementsToken: "ENTITLEMENTS_TOKEN",
				cookies: [],
				location: .europe,
				userID: Self.playerID
			),
			urlSessionOverride: verifyingURLSession()
		)
	}
}
