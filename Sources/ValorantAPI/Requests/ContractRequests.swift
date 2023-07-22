import Foundation
import Protoquest

extension ValorantClient {
	/// - Note: This request requires that you've set ``ValorantClient/clientVersion`` appropriately!
	public func getContractDetails() async throws -> ContractDetails {
		try await send(ContractDetailsRequest(playerID: userID))
	}
	
	/// - Note: This request requires that you've set ``ValorantClient/clientVersion`` appropriately!
	public func getAgentContractProgress(for agent: Agent.ID) async throws -> AgentContractProgress {
		try await send(AgentContractProgressRequest(playerID: userID, agentID: agent))
	}
	
	/// - Note: This request requires that you've set ``ValorantClient/clientVersion`` appropriately!
	public func getDailyTicketProgress(autoRenew: Bool = true) async throws -> DailyTicketProgress {
		try await autoRenew
		? send(RenewDailyTicketRequest(playerID: userID)).dailyRewards
		: send(DailyTicketRequest(playerID: userID)).dailyRewards
	}
	
	/// - Note: This request requires that you've set ``ValorantClient/clientVersion`` appropriately!
	public func getContractsProgress() async throws -> ContractsProgress {
		async let contracts = getContractDetails()
		async let daily = getDailyTicketProgress()
		return try await .init(contracts: contracts, daily: daily)
	}
}

public struct ContractsProgress {
	public var contracts: ContractDetails
	public var daily: DailyTicketProgress
	public var fetchTime = Date.now
	
	public var dailyRefresh: Date {
		fetchTime + daily.remainingTime
	}
	
	public init(contracts: ContractDetails, daily: DailyTicketProgress) {
		self.contracts = contracts
		self.daily = daily
	}
}

private struct ContractDetailsRequest: GetJSONRequest, GameDataRequest {
	var playerID: Player.ID
	
	var path: String {
		"/contracts/v1/contracts/\(playerID)"
	}
	
	typealias Response = ContractDetails
}

private struct AgentContractProgressRequest: GetJSONRequest, GameDataRequest {
	var playerID: Player.ID
	var agentID: Agent.ID
	
	var path: String {
		"/contracts/v1/agents/\(agentID)/progress/\(playerID)"
	}
	
	typealias Response = AgentContractProgress
}

private struct DailyTicketRequest: GetJSONRequest, GameDataRequest {
	var playerID: Player.ID
	
	var path: String {
		"/daily-ticket/v1/\(playerID)"
	}
	
	typealias Response = DailyTicketResponse
}

private struct RenewDailyTicketRequest: JSONJSONRequest, GameDataRequest {
	var playerID: Player.ID
	let body = Body()
	
	var path: String {
		"/daily-ticket/v1/\(playerID)/renew"
	}
	
	struct Body: Codable {}
	typealias Response = DailyTicketResponse
}

struct DailyTicketResponse: Codable {
	var dailyRewards: DailyTicketProgress
	
	private enum CodingKeys: String, CodingKey {
		case dailyRewards = "DailyRewards"
	}
}
