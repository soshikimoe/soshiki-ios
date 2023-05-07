//
//  LibraryObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(LibrariesObject)
class LibrariesObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<LibrariesObject> {
        NSFetchRequest(entityName: "Libraries")
    }

    @NSManaged var libraries: NSSet

    func set(_ libraries: Libraries, context: NSManagedObjectContext) {
        self.libraries.compactMap({ $0 as? FullLibraryObject }).forEach({ removeFromLibraries($0) })
        let textLibraryObject = FullLibraryObject(context: context)
        textLibraryObject.set(libraries.text, mediaType: .text, context: context)
        addToLibraries(textLibraryObject)
        let imageLibraryObject = FullLibraryObject(context: context)
        imageLibraryObject.set(libraries.image, mediaType: .image, context: context)
        addToLibraries(imageLibraryObject)
        let videoLibraryObject = FullLibraryObject(context: context)
        videoLibraryObject.set(libraries.video, mediaType: .video, context: context)
        addToLibraries(videoLibraryObject)
    }

    func get() -> Libraries {
        Libraries(
            text: (libraries.first(where: {
                ($0 as? FullLibraryObject)?.type == MediaType.text.rawValue
            }) as? FullLibraryObject)?.get() ?? FullLibrary(all: Library(ids: []), categories: []),
            image: (libraries.first(where: {
                ($0 as? FullLibraryObject)?.type == MediaType.image.rawValue
            }) as? FullLibraryObject)?.get() ?? FullLibrary(all: Library(ids: []), categories: []),
            video: (libraries.first(where: {
                ($0 as? FullLibraryObject)?.type == MediaType.video.rawValue
            }) as? FullLibraryObject)?.get() ?? FullLibrary(all: Library(ids: []), categories: [])
        )
    }
}

extension LibrariesObject {
    @objc(addLibrariesObject:)
    @NSManaged func addToLibraries(_ value: FullLibraryObject)
    @objc(removeLibrariesObject:)
    @NSManaged func removeFromLibraries(_ value: FullLibraryObject)
    @objc(addLibraries:)
    @NSManaged func addToLibraries(_ values: NSSet)
    @objc(removeLibraries:)
    @NSManaged func removeFromLibraries(_ values: NSSet)
}

@objc(FullLibraryObject)
class FullLibraryObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FullLibraryObject> {
        NSFetchRequest(entityName: "FullLibrary")
    }

    @NSManaged var type: String

    @NSManaged var all: LibraryObject
    @NSManaged var categories: NSOrderedSet

    func set(_ fullLibrary: FullLibrary, mediaType: MediaType, context: NSManagedObjectContext) {
        let libaryObject = LibraryObject(context: context)
        libaryObject.set(fullLibrary.all, context: context)
        self.all = libaryObject
        for category in fullLibrary.categories {
            if let categoryObject = categories.compactMap({ $0 as? LibraryCategoryObject }).first(where: {
                $0.id == category.id
            }) {
                categoryObject.set(category, context: context)
            } else {
                let categoryObject = LibraryCategoryObject(context: context)
                categoryObject.set(category, context: context)
                addToCategories(categoryObject)
            }
        }
        categories.compactMap({ $0 as? LibraryCategoryObject }).forEach({ categoryObject in
            if !fullLibrary.categories.contains(where: { $0.id == categoryObject.id }) {
                removeFromCategories(categoryObject)
            }
        })
    }

    func get() -> FullLibrary {
        FullLibrary(
            all: all.get(),
            categories: categories.compactMap({ ($0 as? LibraryCategoryObject)?.get() })
        )
    }
}

extension FullLibraryObject {
    @objc(addCategoriesObject:)
    @NSManaged func addToCategories(_ value: LibraryCategoryObject)
    @objc(removeCategoriesObject:)
    @NSManaged func removeFromCategories(_ value: LibraryCategoryObject)
    @objc(addCategories:)
    @NSManaged func addToCategories(_ values: NSOrderedSet)
    @objc(removeCategories:)
    @NSManaged func removeFromCategories(_ values: NSOrderedSet)
}

@objc(LibraryObject)
class LibraryObject: NSManagedObject {
    @NSManaged var ids: NSOrderedSet

    func set(_ library: Library, context: NSManagedObjectContext) {
        for id in library.ids {
            if let idObject = ids.compactMap({ $0 as? LibraryIdObject }).first(where: {
                $0.value == id
            }) {
                idObject.value = id
            } else {
                let idObject = LibraryIdObject(context: context)
                idObject.value = id
                addToIds(idObject)
            }
        }
        ids.compactMap({ $0 as? LibraryIdObject }).forEach({ idObject in
            if !library.ids.contains(where: { $0 == idObject.value }) {
                removeFromIds(idObject)
            }
        })
    }
    func get() -> Library {
        Library(
            ids: ids.compactMap({ ($0 as? LibraryIdObject)?.value })
        )
    }
}

extension LibraryObject {
    @objc(addIdsObject:)
    @NSManaged func addToIds(_ value: LibraryIdObject)
    @objc(removeIdsObject:)
    @NSManaged func removeFromIds(_ value: LibraryIdObject)
    @objc(addIds:)
    @NSManaged func addToIds(_ values: NSOrderedSet)
    @objc(removeIds:)
    @NSManaged func removeFromIds(_ values: NSOrderedSet)
}

@objc(LibraryCategoryObject)
class LibraryCategoryObject: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String

    @NSManaged var ids: NSOrderedSet

    func set(_ libraryCategory: LibraryCategory, context: NSManagedObjectContext) {
        self.id = libraryCategory.id
        self.name = libraryCategory.name
        for id in libraryCategory.ids {
            if let idObject = ids.compactMap({ $0 as? LibraryCategoryIdObject }).first(where: {
                $0.value == id
            }) {
                idObject.value = id
            } else {
                let idObject = LibraryCategoryIdObject(context: context)
                idObject.value = id
                addToIds(idObject)
            }
        }
        ids.compactMap({ $0 as? LibraryCategoryIdObject }).forEach({ idObject in
            if !libraryCategory.ids.contains(where: { $0 == idObject.value }) {
                removeFromIds(idObject)
            }
        })
    }

    func get() -> LibraryCategory {
        LibraryCategory(
            id: id,
            name: name,
            ids: ids.compactMap({ ($0 as? LibraryCategoryIdObject)?.value })
        )
    }
}

extension LibraryCategoryObject {
    @objc(addIdsObject:)
    @NSManaged func addToIds(_ value: LibraryCategoryIdObject)
    @objc(removeIdsObject:)
    @NSManaged func removeFromIds(_ value: LibraryCategoryIdObject)
    @objc(addIds:)
    @NSManaged func addToIds(_ values: NSOrderedSet)
    @objc(removeIds:)
    @NSManaged func removeFromIds(_ values: NSOrderedSet)
}

@objc(LibraryIdObject)
class LibraryIdObject: NSManagedObject {
    @NSManaged var value: String
}

@objc(LibraryCategoryIdObject)
class LibraryCategoryIdObject: NSManagedObject {
    @NSManaged var value: String
}
