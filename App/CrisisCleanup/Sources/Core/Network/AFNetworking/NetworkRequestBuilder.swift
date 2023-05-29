// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation
import Alamofire

extension NetworkRequest {
	// A default style constructor for the .copy fn to use
	init(
		url: URL,
		method: HTTPMethod,
		headers: HTTPHeaders?,
		parameters: Encodable?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.url = url
		self.method = method
		self.headers = headers
		self.parameters = parameters
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> NetworkRequest {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toNetworkRequest()
	}

	struct Builder {
		var url: URL
		var method: HTTPMethod
		var headers: HTTPHeaders?
		var parameters: Encodable?

		fileprivate init(original: NetworkRequest) {
			self.url = original.url
			self.method = original.method
			self.headers = original.headers
			self.parameters = original.parameters
		}

		fileprivate func toNetworkRequest() -> NetworkRequest {
			return NetworkRequest(
				url: url,
				method: method,
				headers: headers,
				parameters: parameters
			)
		}
	}
}
