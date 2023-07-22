import XCTest
import HandyOperators
import ArrayBuilder

/// Verifies that the given block causes requests in the given order. Make sure that all communication runs via ``verifyingURLSession``.
func testCommunication<T>(
	running block: () async throws -> T,
	file: StaticString = #filePath, line: UInt = #line,
	@ArrayBuilder<any ExpectationEntry> expecting order: () throws -> [any ExpectationEntry]
) async rethrows -> T {
	verifier = .init(expecting: try order(), file: file, line: line)
	defer { verifier.finalize() }
	
	return try await block()
}

/// A URLSession tht uses a request verifier to verify incoming requests and provide mock responses.
func verifyingURLSession() -> URLSession {
	.init(
		configuration: .ephemeral <- {
			$0.protocolClasses!.insert(VerifyingProtocol.self, at: 0)
		}
	)
}

private var verifier: RequestVerifier!

private final class RequestVerifier {
	var expectedOrder: [any ExpectationEntry]
	var currentPosition = 0
	var file: StaticString
	var line: UInt
	
	init(expecting expectedOrder: [any ExpectationEntry], file: StaticString = #filePath, line: UInt = #line) {
		self.expectedOrder = expectedOrder
		self.file = file
		self.line = line
	}
	
	func validate(_ request: URLRequest) -> ValidationResult {
		XCTAssert(
			currentPosition < expectedOrder.endIndex,
			"Too many requests sent!",
			file: file, line: line
		)
		let result = expectedOrder[currentPosition].validate(request)
		if result.isExhausted {
			currentPosition += 1
		}
		return result
	}
	
	func next() -> any ExpectationEntry {
		defer { currentPosition += 1 }
		XCTAssert(
			currentPosition < expectedOrder.endIndex,
			"Too many requests sent!",
			file: file, line: line
		)
		return expectedOrder[currentPosition < expectedOrder.endIndex ? currentPosition : 0]
	}
	
	func finalize() {
		XCTAssertEqual(
			currentPosition, expectedOrder.endIndex,
			"Not all expected requests were executed!",
			file: file, line: line
		)
	}
}

private final class VerifyingProtocol: URLProtocol {
	override class func canInit(with request: URLRequest) -> Bool { true }
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
	
	override func startLoading() {
		let result = verifier.validate(request)
		
		client!.urlProtocol(self, didReceive: result.response, cacheStoragePolicy: .notAllowed)
		if let body = result.body {
			client!.urlProtocol(self, didLoad: body)
		}
		client!.urlProtocolDidFinishLoading(self)
	}
	
	override func stopLoading() {}
}
