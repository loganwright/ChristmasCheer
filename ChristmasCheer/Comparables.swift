//
//  Comparables.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/25/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import Foundation

extension NSDate : Comparable {}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}
public func <=(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 <= rhs.timeIntervalSince1970
}
public func >=(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 >= rhs.timeIntervalSince1970
}
public func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.timeIntervalSince1970 > rhs.timeIntervalSince1970
}

import Foundation

extension String: Error {}

extension Result where Success: Decodable {
    func unwrap() throws -> Decodable {
        switch self {
        case .success(let d):
            return d
        case .failure(let e):
            throw e
        }
    }
}

extension Formatter {
    static let psql: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

extension JSONDecoder {
    static var cheery: JSONDecoder {
        let js = JSONDecoder()
        js.dateDecodingStrategy = .formatted(Formatter.psql)
        return js
    }
}

extension Result where Success == NetworkResponse {
    func unwrap<D: Decodable>(as: D.Type) throws -> D {
        switch self {
        case .success(let resp):
            guard let data = resp.data else { throw "expected data on response: \(resp.http)" }
            return try JSONDecoder.cheery.decode(D.self, from: data)
        case .failure(let error):
            throw error
        }
    }

    func complete<D: Decodable>(with completion: @escaping (Result<D, Error>) -> Void) {
        do {
            let ob = try self.unwrap(as: D.self)
            completion(.success(ob))
        } catch {
            completion(.failure(error))
        }
    }
}

struct Networking {
    static func get<D: Decodable>(from url: String, expecting: D.Type = D.self, completion: @escaping (Result<D, Error>) -> Void) {
        Networking.send("GET", to: url) { result in
            result.complete(with: completion)
        }
    }

    static func post<E: Encodable, D: Decodable>(_ e: E, to url: String, expecting: D.Type = D.self, completion: @escaping (Result<D, Error>) -> Void) {
        let body: Data
        do { body = try JSONEncoder().encode(e) }
        catch {
            completion(.failure(error))
            return
        }

        Networking.send("POST", to: url, body: body) { result in
            result.complete(with: completion)
        }
    }

    static func send(_ method: String,
                     to _url: String,
                     headers: [String: String] = ["Content-Type": "application/json"],
                     body: Data? = nil,
                     completion: @escaping (Result<NetworkResponse, Error>) -> Void) {

        guard let url = URL(string: _url) else {
             completion(.failure("unable to make url from \(_url)"))
             return
         }

        var request = URLRequest(url: url)
        request.httpMethod = method

        headers.forEach { field, value in
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = body

         URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            } else if let response = response {
                completion(.success(.init(http: response, data: data)))
            } else {
                completion(.failure("no error, or response, idk.."))
            }
         }
         .resume()
    }
}

struct NetworkResponse {
    let http: URLResponse
    let data: Data?
}

struct CheerUser: Decodable {
    let name: String
    let uuid: UUID
    let createdAt: Date
}

private struct Installation: Encodable {
    let associatedUser: UUID
    let deviceToken: Data
    let os: String = "ios"
}

struct Backend {
    static let baseUrl = "http://localhost:8080"
    static let usersUrl = baseUrl + "/users"
    static let installationsUrl = baseUrl + "/installations"

    static func makeUser(name: String, completion: @escaping (Result<CheerUser, Error>) -> Void) {
        Networking.post(["name": name], to: usersUrl, completion: completion)
    }

    static func getUsers(completion: @escaping (Result<[CheerUser], Error>) -> Void) {
        Networking.get(from: usersUrl, completion: completion)
    }

    static func makeInstallation(deviceToken: Data, for user: UUID, completion: @escaping (Result<Int, Error>) -> Void) {
        let package = Installation(associatedUser: user, deviceToken: deviceToken)
        Networking.post(package, to: installationsUrl, completion: completion)
    }
}
