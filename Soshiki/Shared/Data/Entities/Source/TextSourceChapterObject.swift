//
//  TextSourceChapterObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(TextSourceChapterObject)
class TextSourceChapterObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<TextSourceChapterObject> {
        NSFetchRequest(entityName: "TextSourceChapter")
    }

    @NSManaged var chapter: Double
    @NSManaged var entryId: String
    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var translator: String?
    @NSManaged var volume: Double

    func set(_ textSourceChapter: TextSourceChapter, context: NSManagedObjectContext) {
        self.chapter = textSourceChapter.chapter
        self.entryId = textSourceChapter.entryId
        self.id = textSourceChapter.id
        self.name = textSourceChapter.name
        self.translator = textSourceChapter.translator
        self.volume = textSourceChapter.volume ?? -1
    }

//    func get() -> TextSourceChapter {
//        TextSourceChapter(
//            id: id,
//            entryId: entryId,
//            name: name,
//            chapter: chapter,
//            volume: volume == -1 ? nil : volume,
//            translator: translator
//        )
//    }
}

@objc(TextSourceChapterDetailsObject)
class TextSourceChapterDetailsObject: NSManagedObject {
    @NSManaged var baseUrl: String?
    @NSManaged var entryId: String
    @NSManaged var html: String
    @NSManaged var id: String

    func set(_ textSourceChapterDetails: TextSourceChapterDetails, context: NSManagedObjectContext) {
        self.baseUrl = textSourceChapterDetails.baseUrl
        self.entryId = textSourceChapterDetails.entryId
        self.html = textSourceChapterDetails.html
        self.id = textSourceChapterDetails.id
    }

    func get() -> TextSourceChapterDetails {
        TextSourceChapterDetails(
            id: id,
            entryId: entryId,
            html: html,
            baseUrl: baseUrl
        )
    }
}
