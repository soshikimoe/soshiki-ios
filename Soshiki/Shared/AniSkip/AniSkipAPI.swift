//
//  AniSkipAPI.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/3/23.
//

import Foundation

class AniSkipAPI {
    static let shared = AniSkipAPI()

    func getTimes(id: String, episode: Double) async -> [AniSkipTime] {
        // swiftlint:ignore:next line_length
        guard let url = URL(string: "https://api.aniskip.com/v2/skip-times/\(id)/\(episode.toTruncatedString())?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=0") else { return [] }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(AniSkipResponse.self, from: data) else { return [] }
        return response.results.compactMap({ result in
            guard let type = AniSkipTimeType(string: result.skipType) else { return nil }
            return AniSkipTime(
                type: type,
                startTime: result.interval.startTime,
                endTime: result.interval.endTime
            )
        })
    }
}

struct AniSkipTime {
    let type: AniSkipTimeType
    let startTime: Double
    let endTime: Double
}

enum AniSkipTimeType: String {
    case op = "Opening"
    case ed = "Ending"
    case mixedOp = "Mixed Opening"
    case mixedEd = "Mixed Ending"
    case recap = "Recap"

    init?(string: String) {
        switch string {
        case "op": self = .op
        case "ed": self = .ed
        case "mixed-op": self = .mixedOp
        case "mixed-ed": self = .mixedEd
        case "recap": self = .recap
        default: return nil
        }
    }
}

struct AniSkipResponse: Codable {
    let found: Bool
    let message: String
    let statusCode: Int
    let results: [AniSkipResults]
}

struct AniSkipResults: Codable {
    let interval: AniSkipInterval
    let skipType: String
    let skipId: String
    let episodeLength: Double
}

struct AniSkipInterval: Codable {
    let startTime: Double
    let endTime: Double
}
