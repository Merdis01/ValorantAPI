import Protoquest

extension ValorantClient {
	public func getPartyID() async throws -> Party.ID? {
		do {
			return try await send(PlayerPartyRequest(playerID: userID))
				.currentPartyID
		} catch APIError.badResponseCode(404, _, _), APIError.resourceNotFound {
			return nil
		}
	}
	
	public func getPartyInfo(for id: Party.ID) async throws -> Party {
		try await send(PartyInfoRequest(partyID: id))
	}
	
	public func getPartyInfo() async throws -> Party? {
		guard let id = try await getPartyID() else { return nil }
		return try await getPartyInfo(for: id)
	}
	
	public func setReady(to isReady: Bool, in party: Party.ID) async throws -> Party {
		try await send(SetReadyRequest(
			partyID: party, playerID: userID,
			isReady: isReady
		))
	}
	
	public func changeQueue(to queue: QueueID, in party: Party.ID) async throws -> Party {
		try await send(ChangeQueueRequest(
			partyID: party,
			queueID: queue
		))
	}
	
	public func joinMatchmaking(in party: Party.ID) async throws -> Party {
		try await send(JoinMatchmakingRequest(partyID: party))
	}
	
	public func leaveMatchmaking(in party: Party.ID) async throws -> Party {
		try await send(LeaveMatchmakingRequest(partyID: party))
	}
}

private struct PlayerPartyRequest: GetJSONRequest, LiveGameRequest {
	var playerID: Player.ID
	
	var path: String {
		"/parties/v1/players/\(playerID)"
	}
	
	struct Response: Decodable {
		var currentPartyID: Party.ID
		// TODO: this also has a requests and invites property, could support that later on
		
		private enum CodingKeys: String, CodingKey {
			case currentPartyID = "CurrentPartyID"
		}
	}
}

private struct PartyInfoRequest: GetJSONRequest, LiveGameRequest {
	var partyID: Party.ID
	
	var path: String {
		"/parties/v1/parties/\(partyID)"
	}
	
	typealias Response = Party
}

private struct SetReadyRequest: JSONJSONRequest, Encodable, LiveGameRequest {
	var partyID: Party.ID
	var playerID: Player.ID
	
	var path: String {
		"/parties/v1/parties/\(partyID)/members/\(playerID)/setReady"
	}
	
	var isReady: Bool
	
	private enum CodingKeys: String, CodingKey {
		case isReady = "ready"
	}
	
	typealias Response = Party
}

private struct ChangeQueueRequest: JSONJSONRequest, Encodable, LiveGameRequest {
	var partyID: Party.ID
	
	var path: String {
		"/parties/v1/parties/\(partyID)/queue"
	}
	
	var queueID: QueueID
	
	private enum CodingKeys: String, CodingKey {
		case queueID = "queueID"
	}
	
	typealias Response = Party
}

private struct JoinMatchmakingRequest: JSONJSONRequest, Encodable, LiveGameRequest {
	var partyID: Party.ID
	
	var path: String {
		"/parties/v1/parties/\(partyID)/matchmaking/join"
	}
	
	private enum CodingKeys: CodingKey {}
	
	typealias Response = Party
}

private struct LeaveMatchmakingRequest: JSONJSONRequest, Encodable, LiveGameRequest {
	var partyID: Party.ID
	
	var path: String {
		"/parties/v1/parties/\(partyID)/matchmaking/leave"
	}
	
	private enum CodingKeys: CodingKey {}
	
	typealias Response = Party
}
