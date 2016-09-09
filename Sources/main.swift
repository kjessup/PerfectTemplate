//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

#if os(macOS)
import Darwin
#else
import SwiftGlibc
#endif

//
class Test: JSONConvertibleObject {
	
	static let registerName = "test"
	
	var one = 0
	
	override init() {
		super.init()
	}
	
	override func setJSONValues(_ values: [String : Any]) {
		self.one = getJSONValue(named: "One", from: values, defaultValue: 42)
	}
	override func getJSONValues() -> [String : Any] {
		return [JSONDecoding.objectIdentifierKey:Test.registerName, "One":1]
	}
}

JSONDecoding.registerJSONDecodable(name: Test.registerName, creator: { return Test() })

do {
	let encoded = try Test().jsonEncodedString()
	let decoded = try encoded.jsonDecode() as? Test
} catch {
	
}
//

//Log.logger = SysLogger()
//Log.debug(message: "Debug message")
//Log.info(message: "Info message")
//Log.warning(message: "Warning message")
//Log.error(message: "Error message")
//Log.critical(message: "Critical message")
//Log.terminal(message: "Terminal message")

// Create our webroot
// This will serve all static content by default
let webRoot = "./webroot"
try Dir(webRoot).create()

struct UploadHandler: MustachePageHandler { // all template handlers must inherit from PageHandler
	
	// This is the function which all handlers must impliment.
	// It is called by the system to allow the handler to return the set of values which will be used when populating the template.
	// - parameter context: The MustacheEvaluationContext which provides access to the WebRequest containing all the information pertaining to the request
	// - parameter collector: The MustacheEvaluationOutputCollector which can be used to adjust the template output. For example a `defaultEncodingFunc` could be installed to change how outgoing values are encoded.
	func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
		var values = MustacheEvaluationContext.MapType()
		values["value"] = "hello"
		contxt.extendValues(with: values)
		collector.defaultEncodingFunc = {
			string in
			return (try? string.jsonEncodedString()) ?? "bad string"
		}
		do {
			try contxt.requestCompleted(withCollector: collector)
		} catch PerfectError.fileError(let code, let msg) where code == ENOENT {
			let response = contxt.webResponse
			response.status = .notFound
			response.appendBody(string: "\(msg)")
			response.completed()
		} catch {
			let response = contxt.webResponse
			response.status = .internalServerError
			response.appendBody(string: "\(error)")
			response.completed()
		}
	}
}

// Add our routes and such
// Register your own routes and handlers
var routes = Routes()
routes.add(method: .get, uri: "test.html", handler: {
    request, response in
	
	let c1 = HTTPCookie(name: " cookie 1", value: "value 1", domain: nil, expires: nil, path: nil, secure: false, httpOnly: false)
	response.addCookie(c1)
	let c2 = HTTPCookie(name: "cookie 2", value: "value 2", domain: nil, expires: .absoluteSeconds(0), path: nil, secure: false, httpOnly: false)
	response.addCookie(c2)
	
	response.setBody(string: "\(request.cookies)")
	response.completed()
	
//	response.status = .movedPermanently
//	response.setHeader(.location, value: "http://www.perfect.org/")
//	response.completed()
	
//	let webRoot = request.documentRoot
//	mustacheRequest(request: request, response: response, handler: UploadHandler(), templatePath: webRoot + "/test.html")
})

struct Filter404: HTTPResponseFilter {
	func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		guard let _ = response.request.scratchPad["TEST"] as? Int else {
			response.status = .internalServerError
			return callback(.halt)
		}
		callback(.continue)
	}
	
	func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
		if case .notFound = response.status {
			response.setBody(string: "Hello. The file \(response.request.path) was not found.")
			response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
			callback(.done)
		} else {
			callback(.continue)
		}
	}
}

struct TestScratchPad: HTTPRequestFilter {
	func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
		request.scratchPad["TEST"] = 1234
		callback(.continue(request, response))
	}
}

let server = HTTPServer()
server.documentRoot = webRoot
server.serverPort = 8181
server.setResponseFilters([(Filter404(), .high)])
server.setRequestFilters([(TestScratchPad(), .high)])
server.addRoutes(routes)

do {
    // Launch the HTTP server on port 8181
    try server.start()
    
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
