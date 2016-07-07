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

Log.logger = SysLogger()

// Initialize base-level services
PerfectServer.initializeServices()

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

// Add our routes and such
// Register your own routes and handlers
Routing.Routes["/"] = {
    request, response in
    
    if let acceptEncoding = request.header(.acceptEncoding) {
        print("Got accept encoding \(acceptEncoding)")
    }
    
//    guard case .get = request.method else {
//        return
//    }
    
    if let foo = request.param(name: "foo") {
        print("Got foo \(foo)")
    }
    
    if let foo = request.param(name: "foo", defaultValue: "default foo") {
        print("Got foo \(foo)")
    }
    
    let foos: [String] = request.params(named: "foo")
    print("Got foo \(foos)")
    
    for (cookieName, cookieValue) in request.cookies {
        print("\(cookieName): \(cookieValue)")
    }
    
    let path = request.path
    
    let cookie = HTTPCookie(name: "cookie-name", value: "the value", domain: nil,
                        expires: .session, path: "/",
                        secure: false, httpOnly: false)
    response.addCookie(cookie)
    
    let docRoot = request.documentRoot
    do {
        let mrPebbles = File("\(docRoot)/mr_pebbles.jpg")
        let imageSize = mrPebbles.size
        let imageBytes = try mrPebbles.readSomeBytes(count: imageSize)
        response.setHeader(.contentType, value: MimeType.forExtension("jpg"))
        response.setHeader(.contentLength, value: "\(imageBytes.count)")
        response.appendBody(bytes: imageBytes)
    } catch {
        response.status = .internalServerError
        response.appendBody(string: "Error handling request: \(error)")
    }
    response.completed()
    
    response.setHeader(.contentType, value: "application/json")
    let d: [String:Any] = ["a":1, "b":0.1, "c": true, "d":[2, 4, 5, 7, 8]]
    
    do {
        try response.setBody(json: d)
    } catch {
        //...
    }
    response.completed()
}

do {
    // Launch the HTTP server on port 8181
    try HTTPServer(documentRoot: webRoot).start(port: 8181)
    
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
