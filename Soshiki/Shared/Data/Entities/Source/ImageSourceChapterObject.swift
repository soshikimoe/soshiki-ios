//
//  ImageSourceChapterObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(ImageSourceChapterObject)
class ImageSourceChapterObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImageSourceChapterObject> {
        NSFetchRequest(entityName: "ImageSourceChapter")
    }

    @NSManaged var chapter: Double
    @NSManaged var volume: Double
    @NSManaged var entryId: String
    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var translator: String?

    func set(_ imageSourceChapter: ImageSourceChapter, context: NSManagedObjectContext) {
        self.chapter = imageSourceChapter.chapter
        self.volume = imageSourceChapter.volume ?? -1
        self.entryId = imageSourceChapter.entryId
        self.id = imageSourceChapter.id
        self.name = imageSourceChapter.name
        self.translator = imageSourceChapter.translator
    }

//    func get() -> ImageSourceChapter {
//        ImageSourceChapter(
//            id: id,
//            entryId: entryId,
//            name: name,
//            chapter: chapter,
//            volume: volume == -1 ? nil : volume,
//            translator: translator
//        )
//    }
}

@objc(ImageSourceChapterDetailsObject)
class ImageSourceChapterDetailsObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImageSourceChapterDetailsObject> {
        NSFetchRequest(entityName: "ImageSourceChapterDetails")
    }

    @NSManaged var entryId: String
    @NSManaged var id: String

    @NSManaged var pages: NSOrderedSet

    func set(_ imageSourceChapterDetails: ImageSourceChapterDetails, context: NSManagedObjectContext) {
        self.entryId = imageSourceChapterDetails.entryId
        self.id = imageSourceChapterDetails.id
        for page in imageSourceChapterDetails.pages {
            if let pageObject = pages.compactMap({ $0 as? ImageSourceChapterPageObject }).first(where: {
                $0.index == page.index && $0.url == page.url && $0.base64 == page.base64
            }) {
                pageObject.set(page, context: context)
            } else {
                let pageObject = ImageSourceChapterPageObject(context: context)
                pageObject.set(page, context: context)
                addToPages(pageObject)
            }
        }
        pages.compactMap({ $0 as? ImageSourceChapterPageObject }).forEach({ pageObject in
            if !imageSourceChapterDetails.pages.contains(where: {
                $0.index == pageObject.index && $0.url == pageObject.url && $0.base64 == pageObject.base64
            }) {
                removeFromPages(pageObject)
            }
        })
    }

    func get() -> ImageSourceChapterDetails {
        ImageSourceChapterDetails(
            id: id,
            entryId: entryId,
            pages: pages.compactMap({ ($0 as? ImageSourceChapterPageObject)?.get() })
        )
    }
}

extension ImageSourceChapterDetailsObject {
    @objc(addPagesObject:)
    @NSManaged func addToPages(_ value: ImageSourceChapterPageObject)
    @objc(removePagesObject:)
    @NSManaged func removeFromPages(_ value: ImageSourceChapterPageObject)
    @objc(addPages:)
    @NSManaged func addToPages(_ values: NSOrderedSet)
    @objc(removePages:)
    @NSManaged func removeFromPages(_ values: NSOrderedSet)
}

@objc(ImageSourceChapterPageObject)
class ImageSourceChapterPageObject: NSManagedObject {
    @NSManaged var index: Int32
    @NSManaged var base64: String?
    @NSManaged var url: String?

    func set(_ imageSourceChapterPage: ImageSourceChapterPage, context: NSManagedObjectContext) {
        self.index = Int32(imageSourceChapterPage.index)
        self.base64 = imageSourceChapterPage.base64
        self.url = imageSourceChapterPage.url
    }

    func get() -> ImageSourceChapterPage {
        ImageSourceChapterPage(
            index: Int(index),
            url: url,
            base64: base64
        )
    }
}
