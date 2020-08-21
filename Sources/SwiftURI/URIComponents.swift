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

/// Uniform Resource Identifier (URI) parser.
///
/// - SeeAlso: [RFC 3986](https://www.ietf.org/rfc/rfc3986.txt)
public struct URIComponents {
    internal struct Authority {
        let host: String
        let port: Int?
    }

    public let scheme: String
    internal let authority: Authority?
    public var host: String? { authority?.host }
    public var port: Int? { authority?.port }
    public let path: String?
    public let query: String?
    public let fragment: String?
}

extension URIComponents {
    public init?(string: String) {
        guard let uri = parseURI(string) else { return nil }
        self = uri
    }

    public init(scheme: String, host: String, port: Int? = nil, path: String? = nil) {
        self.scheme = scheme
        authority = .init(host: host, port: port)
        self.path = path
        query = nil
        fragment = nil
    }
}

// MARK: - Parser by Point-Free, see https://www.pointfree.co/collections/parsing

struct Parser<A> {
    let run: (inout Substring) -> A?
}

let int = Parser<Int> { str in
    let prefix = str.prefix(while: { $0.isNumber })
    let match = Int(prefix)
    str.removeFirst(prefix.count)
    return match
}

let double = Parser<Double> { str in
    let prefix = str.prefix(while: { $0.isNumber || $0 == "." })
    let match = Double(prefix)
    str.removeFirst(prefix.count)
    return match
}

let char = Parser<Character> { str in
    guard !str.isEmpty else { return nil }
    return str.removeFirst()
}

func literal(_ p: String) -> Parser<Void> {
    Parser<Void> { str in
        guard str.hasPrefix(p) else { return nil }
        str.removeFirst(p.count)
        return ()
    }
}

func always<A>(_ a: A) -> Parser<A> {
    Parser<A> { _ in a }
}

extension Parser {
    static var never: Parser {
        Parser { _ in nil }
    }
}

// zip: (F<A>, F<B>) -> F<(A, B)>
func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    Parser<(A, B)> { str -> (A, B)? in
        let original = str
        guard let matchA = a.run(&str) else { return nil }
        guard let matchB = b.run(&str) else {
            str = original
            return nil
        }
        return (matchA, matchB)
    }
}

func zip<A, B, C>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>) -> Parser<(A, B, C)> {
    zip(a, zip(b, c)).map { a, bc in (a, bc.0, bc.1) }
}

extension Parser {
    func run(_ str: String) -> (match: A?, rest: Substring) {
        var str = str[...]
        let match = run(&str)
        return (match, str)
    }
}

extension Parser {
    // map: (Parser<A>, (A) -> B) -> Parser<B>
    func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        Parser<B> { str -> B? in
            self.run(&str).map(f)
        }
    }
}

extension Parser {
    // flatMap: ((A) -> M<B>) -> (M<A>) -> M<B>
    func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        Parser<B> { str -> B? in
            let original = str
            let matchA = self.run(&str)
            let parserB = matchA.map(f)
            guard let matchB = parserB?.run(&str) else {
                str = original
                return nil
            }
            return matchB
        }
    }
}

// MARK: - URI Parser

func prefix(while predicate: @escaping (Character) throws -> Bool) -> Parser<Substring> {
    Parser<Substring> { str in
        guard let prefix = try? str.prefix(while: predicate), !prefix.isEmpty else { return nil }
        str.removeFirst(prefix.count)
        return prefix
    }
}

func delimiter(_ char: Character) -> Parser<Substring> {
    prefix(while: { $0 != char })
}

let uriScheme = zip(delimiter(":"), literal(":")).map(\.0)

let uriAuthorityString = zip(literal("//"), prefix(while: { $0 != "/" && $0 != "?" && $0 != "#" })).map(\.1)

let uriPath = delimiter("?")

let uriQuery = zip(literal("?"), delimiter("#")).map(\.1)

let uriFragment = zip(literal("#"), prefix(while: { _ in true })).map(\.1)

let uriAuthority = Parser<URIComponents.Authority> { str in
    // TODO: parse userinfo
    guard
        literal("//").run(&str) != nil,
        let host = prefix(while: { $0 != ":" && $0 != "/" && $0 != "?" && $0 != "#" }).run(&str)
    else {
        return nil
    }
    let port: Int? = zip(literal(":"), int).map(\.1).run(&str)
    return .init(host: percentDecode(host), port: port)
}

let unicodeScalar = zip(char, char).flatMap { chars in
    Parser<Character> { _ in
        guard
            let hexValue = Int("\(chars.0)\(chars.1)", radix: 16),
            let scalar = Unicode.Scalar(hexValue)
        else {
            return nil
        }
        return Character(scalar)
    }
}

let percentDecodedChar = zip(literal("%"), unicodeScalar).map(\.1)

func percentDecode(_ str: Substring) -> String {
    var str = str[...]
    var buf = String()
    var substr: Substring?
    var char: Character?
    repeat {
        substr = prefix(while: { $0 != "%" }).run(&str)
        if let substr = substr {
            buf.append(contentsOf: substr)
        }
        char = percentDecodedChar.run(&str)
        if let char = char {
            buf.append(char)
        }
    } while substr != nil || char != nil
    return buf
}

func parseURI(_ str: String) -> URIComponents? {
    var str = str[...]

    guard
        let scheme = uriScheme.run(&str)
    else {
        return nil
    }

    let authority = uriAuthority.run(&str)
    let path = uriPath.run(&str)
    let query = uriQuery.run(&str)
    let fragment = uriFragment.run(&str)

    return URIComponents(
        scheme: String(scheme),
        authority: authority,
        path: path.flatMap(String.init),
        query: query.flatMap(String.init),
        fragment: fragment.flatMap(String.init)
    )
}
