//
//  SoshikiAPI.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/15/22.
//

import Foundation
import SafariServices

class SoshikiAPI {
    static let shared = SoshikiAPI()

    static let baseUrl = "https://api.soshiki.moe"

    var token: String?

    lazy var loginViewController = SFSafariViewController(url: self.loginUrl)

    init() {
        token = KeychainManager.shared.get("soshiki.api.access")
    }

    // MARK: - Entry

    func getEntry(mediaType: MediaType, id: String) async -> Result<Entry, Error> {
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)") else {
                return .failure(APIError("Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)'."))
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Entry.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
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
                return .failure(APIError(
                    "Could not create URL from '\(urlString + (queryItems.isEmpty ? "" : ("?" + queryItems.joined(separator: "&"))))'."
                ))
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode([Entry].self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
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
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            let query = [
                "platformId=" + platformId,
                "platformName=" + platformName,
                "sourceId=" + sourceId,
                "sourceName=" + sourceName,
                "entryId=" + entryId
            ].joined(separator: "&")
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)/link?\(query)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/\(id)/link?\(query)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
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
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/entry/\(mediaType.rawValue.lowercased())/link?\(query)'."
                ))
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode([Entry].self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - User

    func getUser(id: String = "me") async -> Result<User, Error> {
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/user/\(id)") else {
                return .failure(APIError("Could not create URL from '\(SoshikiAPI.baseUrl)/user/\(id)'."))
            }
            var request = URLRequest(url: url)
            if id == "me" {
                if let token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                } else {
                    return .failure(UnauthorizedError())
                }
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(User.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - History

    func getHistory(mediaType: MediaType, id: String) async -> Result<History, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(History.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    func getHistories(mediaType: MediaType) async -> Result<[History], Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode([History].self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    func getAllHistories() async -> Result<Histories, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Histories.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func setHistory(mediaType: MediaType, id: String, query: [HistoryQuery]) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
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
                case .status(let status): queryItems.append("status=\(status.rawValue)")
                }
            }
            urlString += queryItems.isEmpty ? "" : ("?" + queryItems.joined(separator: "&"))
            guard let url = URL(string: urlString) else { return .failure(APIError("Could not create URL from '\(urlString)'.")) }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
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
        case score(Double)
        case status(History.Status)
    }

    @discardableResult
    func deleteHistory(mediaType: MediaType, id: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/history/\(mediaType.rawValue.lowercased())/\(id)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Library

    func getLibraryCategory(mediaType: MediaType, id: String) async -> Result<LibraryCategory, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(LibraryCategory.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    func getLibrary(mediaType: MediaType) async -> Result<Library, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Library.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    func getFullLibrary(mediaType: MediaType) async -> Result<FullLibrary, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(FullLibrary.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    func getLibraries() async -> Result<Libraries, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(try JSONDecoder().decode(Libraries.self, from: data))
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addEntryToLibraryCategory(mediaType: MediaType, id: String, entryId: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addEntryToLibrary(mediaType: MediaType, entryId: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func addLibraryCategory(mediaType: MediaType, id: String, name: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)?name=\(name)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)?name=\(name)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteEntryFromLibraryCategory(mediaType: MediaType, id: String, entryId: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)/\(entryId)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteEntryFromLibrary(mediaType: MediaType, entryId: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/all/\(entryId)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
            }
        } catch {
            return .failure(error)
        }
    }

    @discardableResult
    func deleteLibraryCategory(mediaType: MediaType, id: String) async -> Result<Void, Error> {
        guard let token else { return .failure(UnauthorizedError()) }
        do {
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/library/\(mediaType.rawValue.lowercased())/category/\(id)'."
                ))
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
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
        loginViewController.dismiss()
        loginViewController = SFSafariViewController(url: loginUrl)
    }

    func logout() {
        KeychainManager.shared.delete("soshiki.api.access")
        KeychainManager.shared.delete("soshiki.api.refresh")
        UserDefaults.standard.removeObject(forKey: "user.id")
        UserDefaults.standard.removeObject(forKey: "user.discord")
        token = nil
    }

    @discardableResult
    func refreshToken() async -> Result<Void, Error> {
        do {
            guard let token = KeychainManager.shared.get("soshiki.api.refresh") else {
                return .failure(APIError("Could not get refresh token."))
            }
            guard let url = URL(string: "\(SoshikiAPI.baseUrl)/oauth2/refresh") else {
                return .failure(APIError(
                    "Could not create URL from '\(SoshikiAPI.baseUrl)/oauth2/refresh'."
                ))
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return .failure(APIError("Could not parse response.")) }
            if response.statusCode == 200 {
                let refreshResponse = try JSONDecoder().decode(SoshikiAPI.RefreshResponse.self, from: data)
                KeychainManager.shared.set(refreshResponse.access, forKey: "soshiki.api.access")
                KeychainManager.shared.set(refreshResponse.refresh, forKey: "soshiki.api.refresh")
                UserDefaults.standard.set(refreshResponse.id, forKey: "user.id")
                UserDefaults.standard.set(refreshResponse.discord, forKey: "user.discord")
                return .success(())
            } else {
                let error = String(data: data, encoding: .utf8)
                return .failure(APIError("API responded with status \(response.statusCode)\(error.flatMap({ ": \($0)" }) ?? "")."))
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
