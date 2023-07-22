import Foundation

struct HeaderNames {
	let authorization = "Authorization"
	let entitlementsToken = "X-Riot-Entitlements-JWT"
	let clientVersion = "X-Riot-ClientVersion"
	let clientPlatform = "X-Riot-ClientPlatform"
	
	fileprivate init() {}
}

// TODO: I really like this approach and would love to move it into Protoquest, maybe even with enums?
extension URLRequest {
	var headers: Headers {
		get { .init(request: self) }
		set { self = newValue.request }
	}
	
	@dynamicMemberLookup
	struct Headers {
		var request: URLRequest
		
		subscript(dynamicMember path: KeyPath<HeaderNames, String>) -> String? {
			get {
				request.value(forHTTPHeaderField: HeaderNames()[keyPath: path])
			}
			set {
				request.setValue(newValue, forHTTPHeaderField: HeaderNames()[keyPath: path])
			}
		}
	}
}
