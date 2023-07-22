import XCTest
@testable import ValorantAPI

final class DecodingTests: XCTestCase {
	func testDecodingCompUpdates() throws {
		let matches = try decode([CompetitiveUpdate].self, fromJSONNamed: "comp_updates")
		//dump(matches)
		XCTAssertEqual(matches.count, 20)
	}
	
	func testDecodingCompSummary() throws {
		let summary = try decode(CareerSummary.self, fromJSONNamed: "career_summary")
		dump(summary)
		//XCTAssertEqual(matches.count, 20)
	}
	
	func testDecodingMatch() throws {
		let details = try decode(MatchDetails.self, fromJSONNamed: "match")
		//dump(details)
		XCTAssertEqual(details.players.count, 10)
		
		_ = try decode(MatchDetails.self, fromJSONNamed: "custom_with_spectators")
	}
	
	func testDecodingDeathmatch() throws {
		let details = try decode(MatchDetails.self, fromJSONNamed: "deathmatch")
		//dump(details)
		XCTAssertEqual(details.players.count, 14)
	}
	
	func testDecodingContracts() throws {
		let details = try decode(ContractDetails.self, fromJSONNamed: "contracts")
		//dump(details)
		XCTAssertEqual(details.contracts.count, 40)
	}
	
	func testDecodingDailyTicket() throws {
		let ticket = try decode(DailyTicketProgress.self, fromJSONNamed: "daily_ticket")
		//dump(details)
		XCTAssertEqual(ticket.milestones.map(\.progress), [4, 3, 0, 0])
	}
	
	func testDecodingLivePregameInfo() throws {
		let pregameInfo = try decode(LivePregameInfo.self, fromJSONNamed: "pregame_match")
		//dump(pregameInfo)
		XCTAssertEqual(pregameInfo.team.players.count, 5)
	}
	
	func testDecodingLiveGameInfo() throws {
		let gameInfo = try decode(LiveGameInfo.self, fromJSONNamed: "live_match")
		//dump(gameInfo)
		XCTAssertEqual(gameInfo.players.count, 10)
	}
	
	func testDecodingParty() throws {
		let party = try decode(Party.self, fromJSONNamed: "party")
		//dump(party)
		XCTAssert(party.queueEntryTime < .now)
		XCTAssert(party.state == .inMatchmaking)
	}
	
	func testDecodingInventory() throws {
		let rawInventory = try decode(APIInventory.self, fromJSONNamed: "inventory")
		let inventory = Inventory(rawInventory)
		dump(inventory)
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let reencoded = String(bytes: try encoder.encode(inventory), encoding: .utf8)!
		print(reencoded)
		XCTAssertEqual(inventory.agents.count, 19)
	}
	
	func testDecodingLoadout() throws {
		let loadout = try decode(Loadout.self, fromJSONNamed: "loadout")
		dump(loadout)
		XCTAssertEqual(loadout.guns.count, 18)
	}
	
	func testDecodingStoreOffers() throws {
		let response = try decode(StoreOffersRequest.Response.self, fromJSONNamed: "store_offers")
		//dump(response)
		print("total VP:", response.offers.map(\.cost[.valorantPoints]!).reduce(0, +))
		XCTAssertEqual(response.offers.count, 597)
	}
	
	func testDecodingStorefront() throws {
		let storefront = try decode(Storefront.self, fromJSONNamed: "storefront")
		dump(storefront)
		XCTAssertEqual(storefront.dailySkinStore.offers.count, 4)
		XCTAssertEqual(storefront.accessoryStore.offers!.count, 4)
		XCTAssertNotNil(storefront.nightMarket)
	}
	
	private func decode<Value>(
		_ value: Value.Type = Value.self,
		fromJSONNamed filename: String
	) throws -> Value where Value: Decodable {
		let url = Bundle.module.url(forResource: "examples/\(filename)", withExtension: "json")!
		let json = try Data(contentsOf: url)
		return try ValorantClient.responseDecoder.decode(Value.self, from: json)
	}
}
