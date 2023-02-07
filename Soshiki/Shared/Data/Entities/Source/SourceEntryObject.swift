//
//  SourceEntryObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(SourceEntryObject)
class SourceEntryObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SourceEntryObject> {
        NSFetchRequest(entityName: "SourceEntry")
    }

    @NSManaged var cover: String
    @NSManaged var desc: String
    @NSManaged var id: String
    @NSManaged var nsfw: String
    @NSManaged var status: String
    @NSManaged var title: String
    @NSManaged var url: String

    @NSManaged var staff: NSOrderedSet
    @NSManaged var tags: NSOrderedSet

    func set(_ sourceEntry: SourceEntry, context: NSManagedObjectContext) {
        self.cover = sourceEntry.cover
        self.desc = sourceEntry.description
        self.id = sourceEntry.id
        self.nsfw = sourceEntry.nsfw.rawValue
        self.status = sourceEntry.status.rawValue
        self.title = sourceEntry.title
        self.url = sourceEntry.url
        for staff in sourceEntry.staff {
            if let staffObject = self.staff.compactMap({ $0 as? SourceEntryStaffObject }).first(where: {
                $0.value == staff
            }) {
                staffObject.value = staff
            } else {
                let staffObject = SourceEntryStaffObject(context: context)
                staffObject.value = staff
                addToStaff(staffObject)
            }
        }
        staff.compactMap({ $0 as? SourceEntryStaffObject }).forEach({ staffObject in
            if !sourceEntry.staff.contains(where: { $0 == staffObject.value }) {
                removeFromStaff(staffObject)
            }
        })
        for tag in sourceEntry.tags {
            if let tagObject = tags.compactMap({ $0 as? SourceEntryTagObject }).first(where: {
                $0.value == tag
            }) {
                tagObject.value = tag
            } else {
                let tagObject = SourceEntryTagObject(context: context)
                tagObject.value = tag
                addToTags(tagObject)
            }
        }
        tags.compactMap({ $0 as? SourceEntryTagObject }).forEach({ tagObject in
            if !sourceEntry.tags.contains(where: { $0 == tagObject.value }) {
                removeFromTags(tagObject)
            }
        })
    }

    func get() -> SourceEntry {
        SourceEntry(
            id: id,
            title: title,
            staff: staff.compactMap({ ($0 as? SourceEntryStaffObject)?.value }),
            tags: tags.compactMap({ ($0 as? SourceEntryTagObject)?.value }),
            cover: cover,
            nsfw: SourceEntryContentRating(rawValue: nsfw) ?? .safe,
            status: SourceEntryStatus(rawValue: status) ?? .unknown,
            url: url,
            description: desc
        )
    }
}

extension SourceEntryObject {
    @objc(addStaffObject:)
    @NSManaged func addToStaff(_ value: SourceEntryStaffObject)
    @objc(removeStaffObject:)
    @NSManaged func removeFromStaff(_ value: SourceEntryStaffObject)
    @objc(addStaff:)
    @NSManaged func addToStaff(_ values: NSOrderedSet)
    @objc(removeStaff:)
    @NSManaged func removeFromStaff(_ values: NSOrderedSet)

    @objc(addTagsObject:)
    @NSManaged func addToTags(_ value: SourceEntryTagObject)
    @objc(removeTagsObject:)
    @NSManaged func removeFromTags(_ value: SourceEntryTagObject)
    @objc(addTags:)
    @NSManaged func addToTags(_ values: NSOrderedSet)
    @objc(removeTags:)
    @NSManaged func removeFromTags(_ values: NSOrderedSet)
}

@objc(SourceEntryStaffObject)
class SourceEntryStaffObject: NSManagedObject {
    @NSManaged var value: String
}

@objc(SourceEntryTagObject)
class SourceEntryTagObject: NSManagedObject {
    @NSManaged var value: String
}
