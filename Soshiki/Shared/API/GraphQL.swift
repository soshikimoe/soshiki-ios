//
//  GraphQL.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/18/22.
//

import Foundation

protocol OptionalProtocol { }
extension Optional: OptionalProtocol { }

struct GraphQL {
    static func query<T: QueryLike>(_ args: T, returning query: [T.QueryType], token: String) async -> T.ReturnType? {
        let argsString = Mirror(reflecting: args).children
            .filter({ _, value in
                if case Optional<Any>.none = value { return false } else { return true }
            }).map({ label, value in
                if value is OptionalProtocol {
                    return (label, (value as? Any?)!!)
                } else {
                    return (label, value)
                }
            }).map({ label, value in
                "\(label ?? ""): \(type(of: value) == String.self ? "\"\(value)\"" : (value as? (any StringRepresentable))?.rawValue ?? value)"
            }).joined(separator: ", ")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let typeName = String(describing: type(of: args)).dropFirst(5)
        let fullQuery = "{\"query\": \"query { \(query.graphql("\(typeName)\(argsString.isEmpty ? "" : "(\(argsString))")")) }\"}"
            .replacing("\n", with: "\\n")
        var request = URLRequest(url: URL(string: SoshikiAPI.baseUrl)!)
        request.httpMethod = "POST"
        request.httpBody = fullQuery.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let value = try? JSONDecoder().decode(GraphQLResponse<T.ReturnType>.self, from: data) {
            return value.data[String(String(describing: type(of: args)).dropFirst(5))] ?? nil
        } else {
            return nil
        }
    }

    static func mutation<T: MutationLike>(_ args: T, returning query: [T.QueryType], token: String) async -> T.ReturnType? {
        let argsString = Mirror(reflecting: args).children
            .filter({ _, value in
                if case Optional<Any>.none = value { return false } else { return true }
            }).map({ label, value in
                if value is OptionalProtocol {
                    return (label, (value as? Any?)!!)
                } else {
                    return (label, value)
                }
            }).map({ label, value in
                "\(label ?? ""): \(type(of: value) == String.self ? "\"\(value)\"" : (value as? (any StringRepresentable))?.rawValue ?? value)"
            }).joined(separator: ", ")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let typeName = String(describing: type(of: args)).dropFirst(8)
        let fullQuery = "{\"query\": \"mutation { \(query.graphql("\(typeName)\(argsString.isEmpty ? "" : "(\(argsString))")")) }\"}"
            .replacing("\n", with: "\\n")
        var request = URLRequest(url: URL(string: SoshikiAPI.baseUrl)!)
        request.httpMethod = "POST"
        request.httpBody = fullQuery.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let value = try? JSONDecoder().decode(GraphQLResponse<T.ReturnType>.self, from: data) {
            return value.data[String(String(describing: type(of: args)).dropFirst(8))] ?? nil
        } else {
            return nil
        }
    }
}

struct GraphQLResponse<T: Codable>: Codable {
    let data: [String: T]
}
