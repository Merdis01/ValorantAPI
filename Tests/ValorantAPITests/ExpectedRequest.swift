import Foundation
import HandyOperators
import XCTest
import ArrayBuilder

/// Describes an expectation of a request that the client should make along with its mocked response.
struct ExpectedRequest {
	let url: Tracked<URL>
	
	var requestBody: Tracked<Data>?
	var method: Tracked<String>
	var responseCode = 200
	var responseBody: Data?
	
	init(to url: URL, file: StaticString = #filePath, line: UInt = #line) {
		self.url = .init(value: url, file: file, line: line)
		self.method = .init(value: "GET", file: file, line: line)
	}
	
	init(to url: String, file: StaticString = #filePath, line: UInt = #line) {
		self.init(to: URL(string: url)!, file: file, line: line)
	}
	
	func method(_ method: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
		self <- { $0.method = .init(value: method, file: file, line: line) }
	}
	
	func post(file: StaticString = #filePath, line: UInt = #line) -> Self {
		method("POST", file: file, line: line)
	}
	
	func put(file: StaticString = #filePath, line: UInt = #line) -> Self {
		method("PUT", file: file, line: line)
	}
	
	func requestBody(_ body: Data, file: StaticString = #filePath, line: UInt = #line) -> Self {
		self <- { $0.requestBody = .init(value: body, file: file, line: line) }
	}
	
	func requestBody(_ body: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
		requestBody(body.data(using: .utf8)!, file: file, line: line)
	}
	
	func requestBody(fileNamed filename: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
		let url = Bundle.module.url(forResource: "examples/\(filename)", withExtension: "json")!
		return requestBody(try! Data(contentsOf: url), file: file, line: line)
	}
	
	func responseCode(_ code: Int) -> Self {
		self <- { $0.responseCode = code }
	}
	
	func responseBody(_ body: Data) -> Self {
		self <- { $0.responseBody = body }
	}
	
	func responseBody(_ body: String) -> Self {
		responseBody(body.data(using: .utf8)!)
	}
	
	func responseBody(fileNamed filename: String) -> Self {
		let url = Bundle.module.url(forResource: "examples/\(filename)", withExtension: "json")!
		return responseBody(try! Data(contentsOf: url))
	}
	
	struct Group {
		var requests: [URL: ExpectedRequest] = [:]
		
		init(@ArrayBuilder<ExpectedRequest> requests: () -> [ExpectedRequest]) {
			for request in requests() {
				add(request)
			}
		}
		
		mutating func add(_ request: ExpectedRequest) {
			let old = requests.updateValue(request, forKey: request.url.value)
			assert(old == nil)
		}
	}
}

struct Tracked<Value> {
	var value: Value
	var file: StaticString = #filePath
	var line: UInt = #line
}

extension Tracked where Value: Equatable {
	func assertEqual(to other: @autoclosure () -> Value) {
		XCTAssertEqual(other(), value, file: file, line: line)
	}
}

protocol ExpectationEntry {
	/// - returns: whether to move on to the next entry now
	mutating func validate(_ request: URLRequest) -> ValidationResult
}

struct ValidationResult {
	let response: HTTPURLResponse
	let body: Data?
	let isExhausted: Bool
}

extension ExpectedRequest: ExpectationEntry {
	func validate(_ request: URLRequest) -> ValidationResult {
		url.assertEqual(to: request.url!)
		method.assertEqual(to: request.httpMethod!)
		
		if let expectedBody = requestBody {
			let actualBody = request.httpBody ?? Data(reading: request.httpBodyStream!)
			expectedBody.assertEqual(to: actualBody)
		}
		
		return ValidationResult(
			response: .init(
				url: url.value,
				statusCode: responseCode,
				httpVersion: nil,
				headerFields: nil
			)!,
			body: responseBody,
			isExhausted: true
		)
	}
}

extension ExpectedRequest.Group: ExpectationEntry {
	mutating func validate(_ request: URLRequest) -> ValidationResult {
		let receiver = requests.removeValue(forKey: request.url!)!
		let result = receiver.validate(request)
		return ValidationResult(
			response: result.response,
			body: result.body,
			isExhausted: requests.isEmpty
		)
	}
}

private extension Data {
	// why this isn't included is beyond me
	init(reading stream: InputStream) {
		self.init()
		
		stream.open()
		defer { stream.close() }
		
		let bufferSize = 1024
		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
		defer { buffer.deallocate() }
		
		while stream.hasBytesAvailable {
			let bytesRead = stream.read(buffer, maxLength: bufferSize)
			append(buffer, count: bytesRead)
		}
	}
}
