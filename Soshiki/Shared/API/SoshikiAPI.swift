//
//  SoshikiAPI.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import Foundation
import SafariServices
import Network

// swiftlint:disable:next type_body_length
class SoshikiAPI {
    static let shared = SoshikiAPI()

    static let baseUrl = "https://api.soshiki.moe"

    var token: String?

    lazy var loginViewController = SFSafariViewController(url: self.loginUrl)

    var isRefreshing = false

    init() {
        token = KeychainManager.shared.get("soshiki.api.access")
    }

    // MARK: - Entry

    func getEntry(mediaType: MediaType, id: String) async -> Result<Entry, Error> {
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)") else {
                throw APIError("Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)'.")
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                let entry = try JSONDecoder().decode(Entry.self, from: data)
//                if let localEntry = DataManager.shared.getEntry(mediaType: entry.mediaType, id: entry._id) {
//                    localEntry.set(entry, context: DataManager.shared.container.viewContext)
//                    DataManager.shared.save()
//                } else {
//                    DataManager.shared.addEntry(entry: entry, save: true)
//                }
                return .success(entry)
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
//            if let localEntry = DataManager.shared.getEntry(mediaType: mediaType, id: id) {
//                return .success(localEntry.get())
//            }
            return .failure(error)
        }
    }

    func getEntries(mediaType: MediaType, query: [EntriesQuery]) async -> Result<[Entry], Error> {
        do {
            let urlString = "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())"
            var queryItems: [String] = []
            for object in query {
                switch object {
                case .title(let title): queryItems.append("title=\(title.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")")
                case .ids(let ids): ids.forEach({ queryItems.append("ids[]=\($0)") })
                case .status(let status): status.forEach({ queryItems.append("status[]=\($0.rawValue)") })
                case .contentRating(let contentRating): contentRating.forEach({ queryItems.append("contentRating[]=\($0.rawValue)") })
                case .limit(let limit): queryItems.append("limit=\(limit)")
                case .offset(let offset): queryItems.append("offset=\(offset)")
                }
            }
            guard let url = URL(string: urlString + (queryItems.isEmpty ? "" : ("?" + queryItems.joined(separator: "&")))) else {
                throw APIError(
                    "Could not create URL from '\(urlString + (queryItems.isEmpty ? "" : ("?" + queryItems.joined(separator: "&"))))'."
                )
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                let entries = try JSONDecoder().decode([Entry].self, from: data)
//                for entry in entries {
//                    if let localEntry = DataManager.shared.getEntry(mediaType: entry.mediaType, id: entry._id) {
//                        localEntry.set(entry, context: DataManager.shared.container.viewContext)
//                    } else {
//                        DataManager.shared.addEntry(entry: entry, save: false)
//                    }
//                }
//                DataManager.shared.save()
                return .success(entries)
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            let fetchRequest = EntryObject.fetchRequest()
            for item in query {
                switch item {
                case .ids(let ids): fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
                case .limit(let limit): fetchRequest.fetchLimit = limit
                case .offset(let offset): fetchRequest.fetchOffset = offset
                default: break
                }
            }
//            if let results = try? DataManager.shared.container.viewContext.fetch(fetchRequest).map({ $0.get() }) {
//                return .success(results)
//            }
            return .failure(error)
        }
    }

    enum EntriesQuery {
        case title(String)
        case ids([String])
        case status([Entry.Status])
        case contentRating([Entry.ContentRating])
        case limit(Int)
        case offset(Int)
    }

    @discardableResult
    func setLink(
        mediaType: MediaType,
        id: String,
        platformId: String,
        platformName: String,
        sourceId: String,
        sourceName: String,
        entryId: String
    ) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            let query = [
                "platformId=" + platformId,
                "platformName=" + platformName,
                "sourceId=" + sourceId,
                "sourceName=" + sourceName,
                "entryId=" + entryId
            ].joined(separator: "&")
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)/link?\(query)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)/link?\(query)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getLink(mediaType: MediaType, platformId: String, sourceId: String, entryId: String) async -> Result<[Entry], Error> {
        do {
            let query = [
                "platformId=" + platformId,
                "sourceId=" + sourceId,
                "entryId=" + entryId
            ].joined(separator: "&")
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/link?\(query)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/link?\(query)'."
                )
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode([Entry].self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - User

    func getUser(id: String = "me") async -> Result<User, Error> {
        do {
            let query = [
                "includes[]=history",
                "includes[]=library",
                "includes[]=connections",
                "includes[]=devices",
                "includes[]=trackers"
            ]
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/user/\(id)?\(query.joined(separator: "&"))") else {
                throw APIError("Could not create URL from '\(SoshikiAPI.baseUrl)/user/\(id)?\(query.joined(separator: "&"))'.")
            }
            var request = URLRequest(url: url)
            if id == "me" {
                if let token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    throw UnauthorizedError()
                }
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(User.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - History

    func getHistory(mediaType: MediaType, id: String) async -> Result<History, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(History.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getHistories(mediaType: MediaType) async -> Result<[History], Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode([History].self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getAllHistories() async -> Result<Histories, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Histories.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func setHistory(mediaType: MediaType, id: String, query: [HistoryQuery]) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            var urlString = "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)"
            var queryItems: [String] = []
            for item in query {
                switch item {
                case .page(let page): queryItems.append("page=\(page)")
                case .chapter(let chapter): queryItems.append("chapter=\(chapter)")
                case .volume(let volume): queryItems.append("volume=\(volume)")
                case .timestamp(let timestamp): queryItems.append("timestamp=\(timestamp)")
                case .episode(let episode): queryItems.append("episode=\(episode)")
                case .score(let score): queryItems.append("score=\(score)")
                case .percent(let percent): queryItems.append("percent=\(percent)")
                case .status(let status): queryItems.append("status=\(status.rawValue)")
                }
            }
            urlString += queryItems.isEmpty ? "" : ("?" + queryItems.joined(separator: "&"))
            guard let url = URL(string: urlString) else { throw APIError("Could not create URL from '\(urlString)'.") }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    enum HistoryQuery {
        case page(Int)
        case chapter(Double)
        case volume(Double)
        case timestamp(Int)
        case episode(Double)
        case percent(Double)
        case score(Double)
        case status(History.Status)
    }

    @discardableResult
    func deleteHistory(mediaType: MediaType, id: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Library

    func getLibraryCategory(mediaType: MediaType, id: String) async -> Result<LibraryCategory, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(LibraryCategory.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getLibrary(mediaType: MediaType) async -> Result<Library, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Library.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getFullLibrary(mediaType: MediaType) async -> Result<FullLibrary, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(FullLibrary.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func getLibraries() async -> Result<Libraries, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Libraries.self, from: data))
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addEntryToLibraryCategory(mediaType: MediaType, id: String, entryId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addEntryToLibrary(mediaType: MediaType, entryId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addLibraryCategory(mediaType: MediaType, id: String, name: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)?name=\(name)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)?name=\(name)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteEntryFromLibraryCategory(mediaType: MediaType, id: String, entryId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteEntryFromLibrary(mediaType: MediaType, entryId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteLibraryCategory(mediaType: MediaType, id: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Login

    var loginUrl: URL {
        URL(string: "\(SoshikiAPI.baseUrl)/oauth2/login?redirectUrl=\("soshiki://login".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)")!
    }

    func loginCallback(_ url: URL) {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let access = items.first(where: { $0.name == "access" })?.value,
              let refresh = items.first(where: { $0.name == "refresh" })?.value,
              let id = items.first(where: { $0.name == "id" })?.value,
              let discord = items.first(where: { $0.name == "discord" })?.value else { return }
        KeychainManager.shared.set(access, forKey: "soshiki.api.access")
        KeychainManager.shared.set(refresh, forKey: "soshiki.api.refresh")
        UserDefaults.standard.set(id, forKey: "user.id")
        UserDefaults.standard.set(discord, forKey: "user.discord")
        self.token = access
        loginViewController.dismiss(animated: true)
        loginViewController = SFSafariViewController(url: loginUrl)
        NotificationCenter.default.post(name: .init(SoshikiAPI.Keys.loggedIn), object: nil)
    }

    func logout() {
        KeychainManager.shared.delete("soshiki.api.access")
        KeychainManager.shared.delete("soshiki.api.refresh")
        UserDefaults.standard.removeObject(forKey: "user.id")
        UserDefaults.standard.removeObject(forKey: "user.discord")
        token = nil
        NotificationCenter.default.post(name: .init(SoshikiAPI.Keys.loggedOut), object: nil)
    }

    @discardableResult
    func refreshToken() async -> Result<Void, Error> {
        isRefreshing = true
        defer {
            isRefreshing = false
        }

        do {
            guard let token = KeychainManager.shared.get("soshiki.api.refresh") else {
                throw APIError("Could not get refresh token.")
            }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/oauth2/refresh") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/oauth2/refresh'."
                )
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                let refreshResponse = try JSONDecoder().decode(SoshikiAPI.RefreshResponse.self, from: data)
                self.token = refreshResponse.access
                KeychainManager.shared.set(refreshResponse.access, forKey: "soshiki.api.access")
                KeychainManager.shared.set(refreshResponse.refresh, forKey: "soshiki.api.refresh")
                UserDefaults.standard.set(refreshResponse.id, forKey: "user.id")
                UserDefaults.standard.set(refreshResponse.discord, forKey: "user.discord")
                NotificationCenter.default.post(name: .init(SoshikiAPI.Keys.loggedIn), object: nil)
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    struct RefreshResponse: Codable {
        let access: String
        let refresh: String
        let expiresIn: Double
        let id: String
        let discord: String
    }

    // MARK: - Notifications

    func addNotificationDevice(id: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/notifications/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/notifications/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func removeNotificationDevice(id: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/notifications/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/notifications/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func addNotificationEntry(mediaType: MediaType, id: String, source: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let deviceId = UserDefaults.standard.string(forKey: "app.notification.id") else { throw APIError("Could not get device ID") }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/\(mediaType.rawValue.lowercased())/\(id)/\(source)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/\(mediaType.rawValue.lowercased())/\(id)/\(source)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func removeNotificationEntry(mediaType: MediaType, id: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let deviceId = UserDefaults.standard.string(forKey: "app.notification.id") else { throw APIError("Could not get device ID") }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/\(mediaType.rawValue.lowercased())/\(id)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/\(mediaType.rawValue.lowercased())/\(id)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func setNotificationBadge(count: Int) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let deviceId = UserDefaults.standard.string(forKey: "app.notification.id") else { throw APIError("Could not get device ID") }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/badge/\(count)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/notifications/\(deviceId)/badge/\(count)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Trackers

    func addTracker(mediaType: MediaType, id: String, trackerId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/trackers/\(mediaType.rawValue.lowercased())/\(id)/\(trackerId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/trackers/\(mediaType.rawValue.lowercased())/\(id)/\(trackerId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }

    func removeTracker(mediaType: MediaType, id: String, trackerId: String) async -> Result<Void, Error> {
        do {
            guard let token else { throw UnauthorizedError() }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/trackers/\(mediaType.rawValue.lowercased())/\(id)/\(trackerId)") else {
                throw APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/trackers/\(mediaType.rawValue.lowercased())/\(id)/\(trackerId)'."
                )
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw APIError("Could not parse response.") }
            if response.statusCode == 200 {
                return .success(())
            } else if response.statusCode == 401 {
                if !isRefreshing {
                    await refreshToken()
                }
                throw UnauthorizedError()
            } else {
                let error = String(data: data, encoding: .utf8)
                throw APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "").")
            }
        } catch {
            return .failure(error)
        }
    }
}

class APIError: Error, CustomStringConvertible {
    var description: String

    init (_ description: String) {
        self.description = description
    }
}

class UnauthorizedError: Error, CustomStringConvertible {
    var description: String = "Unauthorized."
}

extension SoshikiAPI {
    class Keys {
        static let loggedIn = "api.user.loggedIn"
        static let loggedOut = "api.user.loggedOut"
    }
}
