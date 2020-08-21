//===----------------------------------------------------------------------===//
//
// This source file is part of swift-uri open source project
//
// Copyright (c) 2020 pokryfka and the swift-uri project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.URL
import struct Foundation.URLComponents
@testable import SwiftURI
import XCTest

final class URIComponentsTests: XCTestCase {
    func testParsingFtpURL() throws {
        let uriComponents = try XCTUnwrap(URIComponents(string: "ftp://ftp.is.co.za/rfc/rfc1808.txt"))
        XCTAssertEqual(uriComponents.scheme, "ftp")
        XCTAssertEqual(uriComponents.host, "ftp.is.co.za")
        XCTAssertNil(uriComponents.port)
        XCTAssertEqual(uriComponents.path, "/rfc/rfc1808.txt")
        XCTAssertNil(uriComponents.query)
        XCTAssertNil(uriComponents.fragment)
    }

    func testParsingHttpURL() throws {
        let uriComponents = try XCTUnwrap(URIComponents(string: "http://www.ietf.org/rfc/rfc2396.txt"))
        XCTAssertEqual(uriComponents.scheme, "http")
        XCTAssertEqual(uriComponents.host, "www.ietf.org")
        XCTAssertNil(uriComponents.port)
        XCTAssertEqual(uriComponents.path, "/rfc/rfc2396.txt")
        XCTAssertNil(uriComponents.query)
        XCTAssertNil(uriComponents.fragment)
    }

    func testParsingHttpsURL() throws {
        let string = "https://someserver.com:8888/some/path?foo=bar#fragment"

        let uriComponents = try XCTUnwrap(URIComponents(string: string))
        XCTAssertEqual(uriComponents.scheme, "https")
        XCTAssertEqual(uriComponents.host, "someserver.com")
        XCTAssertEqual(uriComponents.path, "/some/path")
        XCTAssertEqual(uriComponents.port, 8888)
        XCTAssertEqual(uriComponents.query, "foo=bar")
        XCTAssertEqual(uriComponents.fragment, "fragment")

        let url = try XCTUnwrap(URL(string: string))
        XCTAssertEqual(url.scheme, uriComponents.scheme)
        XCTAssertEqual(url.host, uriComponents.host)
        XCTAssertEqual(url.port, uriComponents.port)
        XCTAssertEqual(url.query, uriComponents.query)
        XCTAssertEqual(url.fragment, uriComponents.fragment)

        let urlComponents = try XCTUnwrap(URLComponents(string: string))
        XCTAssertEqual(urlComponents.scheme, uriComponents.scheme)
        XCTAssertEqual(urlComponents.host, uriComponents.host)
        XCTAssertEqual(urlComponents.port, uriComponents.port)
        XCTAssertEqual(urlComponents.query, uriComponents.query)
        XCTAssertEqual(urlComponents.fragment, uriComponents.fragment)
    }

    func testParsingHttpsNoPathURI() throws {
        let uriComponents = try XCTUnwrap(URIComponents(string: "http://someserver.com"))
        XCTAssertEqual(uriComponents.scheme, "http")
        XCTAssertEqual(uriComponents.host, "someserver.com")
        XCTAssertNil(uriComponents.path)
        XCTAssertNil(uriComponents.port)
        XCTAssertNil(uriComponents.query)
        XCTAssertNil(uriComponents.fragment)
    }

    func testParsingUnixURI() throws {
        let uriComponents = try XCTUnwrap(URIComponents(string: "unix:///tmp/file"))
        XCTAssertEqual(uriComponents.scheme, "unix")
        XCTAssertNil(uriComponents.host)
        XCTAssertEqual(uriComponents.path, "/tmp/file")
    }

    func testParsingHttpPlusUnixURI() throws {
        let string = "http+unix://%2Ftmp%2Ffile/file/path"

        let uriComponents = try XCTUnwrap(URIComponents(string: string))
        XCTAssertEqual(uriComponents.scheme, "http+unix")
        XCTAssertEqual(uriComponents.host, "/tmp/file")
        XCTAssertEqual(uriComponents.path, "/file/path")

        let url = try XCTUnwrap(URL(string: string))
        XCTAssertEqual(url.scheme, "http+unix")
        XCTAssertEqual(url.host, "/tmp/file")

        let urlComponents = try XCTUnwrap(URLComponents(string: string))
        XCTAssertEqual(urlComponents.scheme, "http+unix")
        XCTAssertEqual(urlComponents.host, "/tmp/file")
        XCTAssertEqual(urlComponents.percentEncodedHost, "%2Ftmp%2Ffile")
    }
}
