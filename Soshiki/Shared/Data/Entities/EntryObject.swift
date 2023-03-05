//
//  EntryObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(EntryObject)
class EntryObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<EntryObject> {
        NSFetchRequest(entityName: "Entry")
    }

    @NSManaged var id: String
    @NSManaged var preferredSource: String?
    @NSManaged var color: String?
    @NSManaged var desc: String?
    @NSManaged var mediaType: String
    @NSManaged var score: Double
    @NSManaged var status: String
    @NSManaged var title: String
    @NSManaged var contentRating: String

    @NSManaged var alternativeTitles: NSOrderedSet
    @NSManaged var banners: NSOrderedSet
    @NSManaged var covers: NSOrderedSet
    @NSManaged var links: NSOrderedSet
    @NSManaged var platforms: NSOrderedSet
    @NSManaged var staff: NSOrderedSet
    @NSManaged var tags: NSOrderedSet
    @NSManaged var trackers: NSOrderedSet

    func set(_ entry: Entry, context: NSManagedObjectContext) {
        self.id = entry._id
        self.color = entry.color
        self.desc = entry.description
        self.mediaType = entry.mediaType.rawValue
        self.score = entry.score ?? -1
        self.status = entry.status.rawValue
        self.title = entry.title
        self.alternativeTitles = NSOrderedSet(array: entry.alternativeTitles.map({ alternativeTitle in
            let alternativeTitleObject = EntryAlternativeTitleObject(context: context)
            alternativeTitleObject.set(alternativeTitle, context: context)
            return alternativeTitleObject
        }))
        for alternativeTitle in entry.alternativeTitles {
            if let alternativeTitleObject = alternativeTitles.compactMap({ $0 as? EntryAlternativeTitleObject }).first(where: {
                $0.title == alternativeTitle.title && $0.type == alternativeTitle.type
            }) {
                alternativeTitleObject.set(alternativeTitle, context: context)
            } else {
                let alternativeTitleObject = EntryAlternativeTitleObject(context: context)
                alternativeTitleObject.set(alternativeTitle, context: context)
                addToAlternativeTitles(alternativeTitleObject)
            }
        }
        alternativeTitles.compactMap({ $0 as? EntryAlternativeTitleObject }).forEach({ alternativeTitleObject in
            if !entry.alternativeTitles.contains(where: { $0.title == alternativeTitleObject.title && $0.type == alternativeTitleObject.type }) {
                removeFromAlternativeTitles(alternativeTitleObject)
            }
        })
        for banner in entry.banners {
            if let bannerObject = banners.compactMap({ $0 as? EntryBannerImageObject }).first(where: {
                $0.image == banner.image && $0.quality == banner.quality.rawValue
            }) {
                bannerObject.set(banner, context: context)
            } else {
                let bannerObject = EntryBannerImageObject(context: context)
                bannerObject.set(banner, context: context)
                addToBanners(bannerObject)
            }
        }
        banners.compactMap({ $0 as? EntryBannerImageObject }).forEach({ bannerObject in
            if !entry.banners.contains(where: { $0.image == bannerObject.image && $0.quality.rawValue == bannerObject.quality }) {
                removeFromBanners(bannerObject)
            }
        })
        for cover in entry.covers {
            if let coverObject = covers.compactMap({ $0 as? EntryCoverImageObject }).first(where: {
                $0.image == cover.image && $0.quality == cover.quality.rawValue
            }) {
                coverObject.set(cover, context: context)
            } else {
                let coverObject = EntryCoverImageObject(context: context)
                coverObject.set(cover, context: context)
                addToCovers(coverObject)
            }
        }
        covers.compactMap({ $0 as? EntryCoverImageObject }).forEach({ coverObject in
            if !entry.covers.contains(where: { $0.image == coverObject.image && $0.quality.rawValue == coverObject.quality }) {
                removeFromCovers(coverObject)
            }
        })
        for link in entry.links {
            if let linkObject = links.compactMap({ $0 as? EntryLinkObject }).first(where: {
                $0.url == link.url && $0.site == link.site
            }) {
                linkObject.set(link, context: context)
            } else {
                let linkObject = EntryLinkObject(context: context)
                linkObject.set(link, context: context)
                addToLinks(linkObject)
            }
        }
        links.compactMap({ $0 as? EntryLinkObject }).forEach({ linkObject in
            if !entry.links.contains(where: { $0.url == linkObject.url && $0.site == linkObject.site }) {
                removeFromLinks(linkObject)
            }
        })
        for platform in entry.platforms {
            if let platformObject = platforms.compactMap({ $0 as? EntryPlatformObject }).first(where: {
                $0.id == platform.id
            }) {
                platformObject.set(platform, context: context)
            } else {
                let platformObject = EntryPlatformObject(context: context)
                platformObject.set(platform, context: context)
                addToPlatforms(platformObject)
            }
        }
        platforms.compactMap({ $0 as? EntryPlatformObject }).forEach({ platformObject in
            if !entry.platforms.contains(where: { $0.id == platformObject.id }) {
                removeFromPlatforms(platformObject)
            }
        })
        for staff in entry.staff {
            if let staffObject = self.staff.compactMap({ $0 as? EntryStaffObject }).first(where: {
                $0.name == staff.name && $0.role == staff.role && $0.image == staff.image
            }) {
                staffObject.set(staff, context: context)
            } else {
                let staffObject = EntryStaffObject(context: context)
                staffObject.set(staff, context: context)
                addToStaff(staffObject)
            }
        }
        staff.compactMap({ $0 as? EntryStaffObject }).forEach({ staffObject in
            if !entry.staff.contains(where: { $0.name == staffObject.name && $0.role == staffObject.role && $0.image == staffObject.image }) {
                removeFromStaff(staffObject)
            }
        })
        for tag in entry.tags {
            if let tagObject = tags.compactMap({ $0 as? EntryTagObject }).first(where: {
                $0.name == tag.name
            }) {
                tagObject.set(tag, context: context)
            } else {
                let tagObject = EntryTagObject(context: context)
                tagObject.set(tag, context: context)
                addToTags(tagObject)
            }
        }
        tags.compactMap({ $0 as? EntryTagObject }).forEach({ tagObject in
            if !entry.tags.contains(where: { $0.name == tagObject.name }) {
                removeFromTags(tagObject)
            }
        })
        for tracker in entry.trackers {
            if let trackerObject = trackers.compactMap({ $0 as? EntryTrackerObject }).first(where: {
                $0.id == tracker.id
            }) {
                trackerObject.set(tracker, context: context)
            } else {
                let trackerObject = EntryTrackerObject(context: context)
                trackerObject.set(tracker, context: context)
                addToTrackers(trackerObject)
            }
        }
        trackers.compactMap({ $0 as? EntryTrackerObject }).forEach({ trackerObject in
            if !entry.trackers.contains(where: { $0.id == trackerObject.id }) {
                removeFromTrackers(trackerObject)
            }
        })
    }

    func get() -> Entry {
        Entry(
            _id: id,
            mediaType: MediaType(rawValue: mediaType)!,
            title: title,
            alternativeTitles: alternativeTitles.compactMap({ ($0 as? EntryAlternativeTitleObject)?.get() }),
            description: desc,
            staff: staff.compactMap({ ($0 as? EntryStaffObject)?.get() }),
            covers: covers.compactMap({ ($0 as? EntryCoverImageObject)?.get() }),
            color: color,
            banners: banners.compactMap({ ($0 as? EntryBannerImageObject)?.get() }),
            score: score,
            contentRating: Entry.ContentRating(rawValue: contentRating) ?? .unknown,
            status: Entry.Status(rawValue: status) ?? .unknown,
            tags: tags.compactMap({ ($0 as? EntryTagObject)?.get() }),
            links: links.compactMap({ ($0 as? EntryLinkObject)?.get() }),
            platforms: platforms.compactMap({ ($0 as? EntryPlatformObject)?.get() }),
            trackers: trackers.compactMap({ ($0 as? EntryTrackerObject)?.get() }),
            skipTimes: nil
        )
    }
}

extension EntryObject {
    @objc(addAlternativeTitlesObject:)
    @NSManaged func addToAlternativeTitles(_ value: EntryAlternativeTitleObject)
    @objc(removeAlternativeTitlesObject:)
    @NSManaged func removeFromAlternativeTitles(_ value: EntryAlternativeTitleObject)
    @objc(addAlternativeTitles:)
    @NSManaged func addToAlternativeTitles(_ values: NSOrderedSet)
    @objc(removeAlternativeTitles:)
    @NSManaged func removeFromAlternativeTitles(_ values: NSOrderedSet)

    @objc(addBannersObject:)
    @NSManaged func addToBanners(_ value: EntryBannerImageObject)
    @objc(removeBannersObject:)
    @NSManaged func removeFromBanners(_ value: EntryBannerImageObject)
    @objc(addBanners:)
    @NSManaged func addToBanners(_ values: NSOrderedSet)
    @objc(removeBanners:)
    @NSManaged func removeFromBanners(_ values: NSOrderedSet)

    @objc(addCoversObject:)
    @NSManaged func addToCovers(_ value: EntryCoverImageObject)
    @objc(removeCoversObject:)
    @NSManaged func removeFromCovers(_ value: EntryCoverImageObject)
    @objc(addCovers:)
    @NSManaged func addToCovers(_ values: NSOrderedSet)
    @objc(removeCovers:)
    @NSManaged func removeFromCovers(_ values: NSOrderedSet)

    @objc(addLinksObject:)
    @NSManaged func addToLinks(_ value: EntryLinkObject)
    @objc(removeLinksObject:)
    @NSManaged func removeFromLinks(_ value: EntryLinkObject)
    @objc(addLinks:)
    @NSManaged func addToLinks(_ values: NSOrderedSet)
    @objc(removeLinks:)
    @NSManaged func removeFromLinks(_ values: NSOrderedSet)

    @objc(addPlatformsObject:)
    @NSManaged func addToPlatforms(_ value: EntryPlatformObject)
    @objc(removePlatformsObject:)
    @NSManaged func removeFromPlatforms(_ value: EntryPlatformObject)
    @objc(addPlatforms:)
    @NSManaged func addToPlatforms(_ values: NSOrderedSet)
    @objc(removePlatforms:)
    @NSManaged func removeFromPlatforms(_ values: NSOrderedSet)

    @objc(addStaffObject:)
    @NSManaged func addToStaff(_ value: EntryStaffObject)
    @objc(removeStaffObject:)
    @NSManaged func removeFromStaff(_ value: EntryStaffObject)
    @objc(addStaff:)
    @NSManaged func addToStaff(_ values: NSOrderedSet)
    @objc(removeStaff:)
    @NSManaged func removeFromStaff(_ values: NSOrderedSet)

    @objc(addTagsObject:)
    @NSManaged func addToTags(_ value: EntryTagObject)
    @objc(removeTagsObject:)
    @NSManaged func removeFromTags(_ value: EntryTagObject)
    @objc(addTags:)
    @NSManaged func addToTags(_ values: NSOrderedSet)
    @objc(removeTags:)
    @NSManaged func removeFromTags(_ values: NSOrderedSet)

    @objc(addTrackersObject:)
    @NSManaged func addToTrackers(_ value: EntryTrackerObject)
    @objc(removeTrackersObject:)
    @NSManaged func removeFromTrackers(_ value: EntryTrackerObject)
    @objc(addTrackers:)
    @NSManaged func addToTrackers(_ values: NSOrderedSet)
    @objc(removeTrackers:)
    @NSManaged func removeFromTrackers(_ values: NSOrderedSet)
}

@objc(EntryAlternativeTitleObject)
class EntryAlternativeTitleObject: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var type: String?

    func set(_ entryAlternativeTitle: Entry.AlternativeTitle, context: NSManagedObjectContext) {
        self.title = entryAlternativeTitle.title
        self.type = entryAlternativeTitle.type
    }

    func get() -> Entry.AlternativeTitle {
        Entry.AlternativeTitle(
            title: title,
            type: type
        )
    }
}

@objc(EntryBannerImageObject)
class EntryBannerImageObject: NSManagedObject {
    @NSManaged var image: String
    @NSManaged var quality: String

    func set(_ entryImage: Entry.Image, context: NSManagedObjectContext) {
        self.image = entryImage.image
        self.quality = entryImage.quality.rawValue
    }

    func get() -> Entry.Image {
        Entry.Image(
            image: image,
            quality: Entry.ImageQuality(rawValue: quality) ?? .unknown
        )
    }
}

@objc(EntryCoverImageObject)
class EntryCoverImageObject: NSManagedObject {
    @NSManaged var image: String
    @NSManaged var quality: String

    func set(_ entryImage: Entry.Image, context: NSManagedObjectContext) {
        self.image = entryImage.image
        self.quality = entryImage.quality.rawValue
    }

    func get() -> Entry.Image {
        Entry.Image(
            image: image,
            quality: Entry.ImageQuality(rawValue: quality) ?? .unknown
        )
    }
}

@objc(EntryLinkObject)
class EntryLinkObject: NSManagedObject {
    @NSManaged var site: String
    @NSManaged var url: String

    func set(_ entryLink: Entry.Link, context: NSManagedObjectContext) {
        self.site = entryLink.site
        self.url = entryLink.url
    }

    func get() -> Entry.Link {
        Entry.Link(
            site: site,
            url: url
        )
    }
}

@objc(EntryPlatformObject)
class EntryPlatformObject: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String

    @NSManaged var sources: NSOrderedSet

    func set(_ entryPlatform: Entry.Platform, context: NSManagedObjectContext) {
        self.id = entryPlatform.id
        self.name = entryPlatform.name
        for source in entryPlatform.sources {
            if let sourceObject = sources.first(where: { ($0 as? EntrySourceObject)?.id == source.id }) as? EntrySourceObject {
                sourceObject.set(source, context: context)
            } else {
                let sourceObject = EntrySourceObject(context: context)
                sourceObject.set(source, context: context)
                addToSources(sourceObject)
            }
        }
        sources.compactMap({ $0 as? EntrySourceObject }).forEach({ sourceObject in
            if !entryPlatform.sources.contains(where: { $0.id == sourceObject.id }) {
                removeFromSources(sourceObject)
            }
        })
    }

    func get() -> Entry.Platform {
        Entry.Platform(
            id: id,
            name: name,
            sources: sources.compactMap({ ($0 as? EntrySourceObject)?.get() })
        )
    }
}

extension EntryPlatformObject {
    @objc(addSourcesObject:)
    @NSManaged func addToSources(_ value: EntrySourceObject)
    @objc(removeSourcesObject:)
    @NSManaged func removeFromSources(_ value: EntrySourceObject)
    @objc(addSources:)
    @NSManaged func addToSources(_ values: NSOrderedSet)
    @objc(removeSources:)
    @NSManaged func removeFromSources(_ values: NSOrderedSet)
}

@objc(EntrySourceObject)
class EntrySourceObject: NSManagedObject {
    @NSManaged var entryId: String
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var user: String?

    func set(_ entrySource: Entry.Source, context: NSManagedObjectContext) {
        self.entryId = entrySource.entryId
        self.id = entrySource.id
        self.name = entrySource.name
        self.user = entrySource.user
    }

    func get() -> Entry.Source {
        Entry.Source(
            id: id,
            name: name,
            entryId: entryId,
            user: user
        )
    }
}

@objc(EntryStaffObject)
class EntryStaffObject: NSManagedObject {
    @NSManaged var image: String?
    @NSManaged var name: String
    @NSManaged var role: String

    func set(_ entryStaff: Entry.Staff, context: NSManagedObjectContext) {
        self.image = entryStaff.image
        self.name = entryStaff.name
        self.role = entryStaff.role
    }

    func get() -> Entry.Staff {
        Entry.Staff(
            name: name,
            role: role,
            image: image
        )
    }
}

@objc(EntryTagObject)
class EntryTagObject: NSManagedObject {
    @NSManaged var name: String

    func set(_ entryTag: Entry.Tag, context: NSManagedObjectContext) {
        self.name = entryTag.name
    }

    func get() -> Entry.Tag {
        Entry.Tag(
            name: name
        )
    }
}

@objc(EntryTrackerObject)
class EntryTrackerObject: NSManagedObject {
    @NSManaged var entryId: String
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var isTracking: Bool

    func set(_ entryTracker: Entry.Tracker, context: NSManagedObjectContext) {
        self.entryId = entryTracker.entryId
        self.id = entryTracker.id
        self.name = entryTracker.name
    }

    func get() -> Entry.Tracker {
        Entry.Tracker(
            id: id,
            name: name,
            entryId: entryId
        )
    }
}
