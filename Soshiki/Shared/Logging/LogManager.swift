//
//  LogManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 5/8/23.
//

import Foundation

class LogManager {
    static let shared = LogManager()

    var logs: [LogObject] = []

    func getLogs(for levels: Set<LogLevel> = [.info, .warn, .error]) -> [LogObject] {
        self.logs.filter({ levels.contains($0.level) })
    }

    func getFormattedLogs(for levels: Set<LogLevel> = [.info, .warn, .error]) -> [String] {
        getLogs(for: levels).map({ "[\($0.level.rawValue)][\($0.time.formatted(.iso8601))] \($0.message)" })
    }

    func log(_ message: String, at level: LogLevel = .info) {
        #if DEBUG
        print("[\(level.rawValue)][\(Date().formatted(.iso8601))] \(message)")
        #endif
        self.logs.append(LogObject(level: level, time: Date(), message: message))
    }
}

// MARK: - LogManager.LogObject

extension LogManager {
    struct LogObject {
        let level: LogLevel
        let time: Date
        let message: String
    }
}

// MARK: - LogManager.LogLevel

extension LogManager {
    enum LogLevel: String {
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
    }
}
