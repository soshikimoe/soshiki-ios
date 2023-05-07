//
//  HistoryObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(HistoriesObject)
class HistoriesObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<HistoriesObject> {
        NSFetchRequest(entityName: "Histories")
    }

    @NSManaged var histories: NSSet

    func set(_ histories: Histories, context: NSManagedObjectContext) {
        let textHistories = histories.text.map({ history in
            let historyObject = HistoryObject(context: context)
            historyObject.set(history, mediaType: .text, context: context)
            return historyObject
        })
        let imageHistories = histories.image.map({ history in
            let historyObject = HistoryObject(context: context)
            historyObject.set(history, mediaType: .image, context: context)
            return historyObject
        })
        let videoHistories = histories.video.map({ history in
            let historyObject = HistoryObject(context: context)
            historyObject.set(history, mediaType: .video, context: context)
            return historyObject
        })
        self.histories = NSSet(array: textHistories + imageHistories + videoHistories)
    }

    func get() -> Histories {
        Histories(
            text: histories.compactMap({ ($0 as? HistoryObject).flatMap({ $0.type == MediaType.text.rawValue ? $0.get() : nil }) }),
            image: histories.compactMap({ ($0 as? HistoryObject).flatMap({ $0.type == MediaType.image.rawValue ? $0.get() : nil }) }),
            video: histories.compactMap({ ($0 as? HistoryObject).flatMap({ $0.type == MediaType.video.rawValue ? $0.get() : nil }) })
        )
    }
}

@objc(HistoryObject)
class HistoryObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<HistoryObject> {
        NSFetchRequest(entityName: "History")
    }

    @NSManaged var chapter: Double
    @NSManaged var episode: Double
    @NSManaged var season: Double
    @NSManaged var id: String
    @NSManaged var page: Int32
    @NSManaged var percent: Double
    @NSManaged var status: String
    @NSManaged var timestamp: Int32
    @NSManaged var type: String
    @NSManaged var volume: Double
    @NSManaged var score: Double

    func set(_ history: History, mediaType: MediaType, context: NSManagedObjectContext) {
        self.chapter = history.chapter ?? -1
        self.episode = history.episode ?? -1
        self.season = history.season ?? -1
        self.id = history.id
        self.page = Int32(history.page ?? -1)
        self.percent = history.percent ?? -1
        self.status = history.status.rawValue
        self.timestamp = Int32(history.timestamp ?? -1)
        self.type = mediaType.rawValue
        self.volume = history.volume ?? -1
    }

    func get() -> History {
        History(
            id: id,
            page: page == -1 ? nil : Int(page),
            chapter: chapter == -1 ? nil : chapter,
            volume: volume == -1 ? nil : volume,
            timestamp: timestamp == -1 ? nil : Int(timestamp),
            episode: episode == -1 ? nil : episode,
            season: season == -1 ? nil : season,
            percent: percent == -1 ? nil : percent,
            score: score == -1 ? nil : score,
            status: History.Status(rawValue: status) ?? .unknown
        )
    }
}
