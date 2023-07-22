import Foundation
import Protoquest
import Collections

public struct ClientLog {
	public let maxCount: Int
	public private(set) var exchanges: Deque<Exchange> = []
	
	public init(maxCount: Int = 50) {
		self.maxCount = maxCount
	}
	
	public mutating func logExchange(request: URLRequest, result: Protoresult) {
		let exchange = Exchange(request: request, result: result)
		guard !exchange.wasCancelled else { return }
		
		if exchanges.count >= maxCount {
			exchanges.removeFirst()
		}
		exchanges.append(exchange)
	}
	
	public struct Exchange: Identifiable {
		public var id = ObjectID<Self, UUID>(rawID: .init())
		public var time = Date.now
		public var request: URLRequest
		public var result: Protoresult
		
		public var statusCode: Int? {
			try? result.get().httpMetadata?.statusCode
		}
		
		var wasCancelled: Bool {
			// hide cancellation errors
			guard
				case .failure(let error) = result,
				let urlError = error as? URLError,
				urlError.code == .cancelled
			else { return false }
			return true
		}
	}
}
