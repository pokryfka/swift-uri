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

@testable import SwiftURI
import XCTest

final class URIParserTests: XCTestCase {
    func testNoScheme() {
        let string = "ftp//ftp.is.co.za/rfc/rfc1808.txt"
        let (result, rem) = uriScheme.run(string)
        XCTAssertNil(result)
        XCTAssertEqual(String(rem), string)
    }

    func testParsingFTP() {
        let string = "ftp://ftp.is.co.za/rfc/rfc1808.txt"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "ftp")
        let authority = uriAuthority.run(&str)
        XCTAssertEqual(authority?.host, "ftp.is.co.za")
        XCTAssertNil(authority?.port)
        XCTAssertEqual(uriPath.run(&str), "/rfc/rfc1808.txt")
        XCTAssertNil(uriQuery.run(&str))
    }

    func testParsingHTTP() {
        let string = "http://www.ietf.org/rfc/rfc2396.txt"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "http")
        let authority = uriAuthority.run(&str)
        XCTAssertEqual(authority?.host, "www.ietf.org")
        XCTAssertNil(authority?.port)
        XCTAssertEqual(uriPath.run(&str), "/rfc/rfc2396.txt")
        XCTAssertNil(uriQuery.run(&str))
    }

    func testParsingLDAP() {
        let string = "ldap://[2001:db8::7]/c=GB?objectClass?one"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "ldap")
        XCTAssertEqual(uriAuthorityString.run(&str), "[2001:db8::7]")
        XCTAssertEqual(uriPath.run(&str), "/c=GB")
        XCTAssertEqual(uriQuery.run(&str), "objectClass?one")
    }

    func testParsingMailto() {
        let string = "mailto:John.Doe@example.com"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "mailto")
        XCTAssertNil(uriAuthorityString.run(&str))
        XCTAssertEqual(uriPath.run(&str), "John.Doe@example.com")
    }

    func testParsingTel() {
        let string = "tel:+1-816-555-1212"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "tel")
        XCTAssertNil(uriAuthorityString.run(&str))
        XCTAssertEqual(uriPath.run(&str), "+1-816-555-1212")
    }

    func testParsingTelnet() {
        let string = "telnet://192.0.2.16:80/"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "telnet")
        let authority = uriAuthority.run(&str)
        XCTAssertEqual(authority?.host, "192.0.2.16")
        XCTAssertEqual(authority?.port, 80)
        XCTAssertEqual(uriPath.run(&str), "/")
        XCTAssertNil(uriQuery.run(&str))
    }

    func testParsingURN() {
        let string = "urn:oasis:names:specification:docbook:dtd:xml:4.1.2"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "urn")
    }

    func testParsingFoo() {
        let string = "foo://info.example.com?fred"
        var str = string[...]
        XCTAssertEqual(uriScheme.run(&str), "foo")
        let authority = uriAuthority.run(&str)
        XCTAssertEqual(authority?.host, "info.example.com")
        XCTAssertNil(authority?.port)
        XCTAssertNil(uriPath.run(&str))
        XCTAssertEqual(uriQuery.run(&str), "fred")
    }
}
