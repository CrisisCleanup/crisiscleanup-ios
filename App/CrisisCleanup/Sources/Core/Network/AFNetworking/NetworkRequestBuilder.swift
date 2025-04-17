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
		additionalPaths: [String]?,
		queryParameters: [URLQueryItem]?,
		formParameters: Encodable?,
		bodyParameters: Encodable?,
		addTokenHeader: Bool,
		clearCookies: Bool,
		timeoutInterval: TimeInterval?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.url = url
		self.method = method
		self.headers = headers
		self.additionalPaths = additionalPaths
		self.queryParameters = queryParameters
		self.formParameters = formParameters
		self.bodyParameters = bodyParameters
		self.addTokenHeader = addTokenHeader
		self.clearCookies = clearCookies
		self.timeoutInterval = timeoutInterval
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
		var additionalPaths: [String]?
		var queryParameters: [URLQueryItem]?
		var formParameters: Encodable?
		var bodyParameters: Encodable?
		var addTokenHeader: Bool
		var clearCookies: Bool
		var timeoutInterval: TimeInterval?

		fileprivate init(original: NetworkRequest) {
			self.url = original.url
			self.method = original.method
			self.headers = original.headers
			self.additionalPaths = original.additionalPaths
			self.queryParameters = original.queryParameters
			self.formParameters = original.formParameters
			self.bodyParameters = original.bodyParameters
			self.addTokenHeader = original.addTokenHeader
			self.clearCookies = original.clearCookies
			self.timeoutInterval = original.timeoutInterval
		}

		fileprivate func toNetworkRequest() -> NetworkRequest {
			return NetworkRequest(
				url: url,
				method: method,
				headers: headers,
				additionalPaths: additionalPaths,
				queryParameters: queryParameters,
				formParameters: formParameters,
				bodyParameters: bodyParameters,
				addTokenHeader: addTokenHeader,
				clearCookies: clearCookies,
				timeoutInterval: timeoutInterval
			)
		}
	}
}
