//
//  DataManager.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

class DataManager {
    static let shared = DataManager()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Soshiki")
        container.loadPersistentStores { _, error in
            if let error {
                LogManager.shared.log("CoreData: Loading persistent stores failed with error \(error)", at: .error)
            }
        }
    }

    func save(force: Bool = false) {
        if force || container.viewContext.hasChanges {
            _ = try? container.viewContext.save()
        }
    }
}

extension DataManager {
    func getEntries() -> [EntryObject] {
        (try? container.viewContext.fetch(EntryObject.fetchRequest())) ?? []
    }

    func getEntry(mediaType: MediaType, id: String) -> EntryObject? {
        let fetchRequest = EntryObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND mediaType == %@", id, mediaType.rawValue)
        fetchRequest.fetchLimit = 1
        return (try? container.viewContext.fetch(fetchRequest))?.first
    }

    func removeEntry(mediaType: MediaType, id: String, save: Bool = false) {
        if let entry = getEntry(mediaType: mediaType, id: id) {
            container.viewContext.delete(entry)
            if save {
                self.save()
            }
        }
    }

    func addEntry(entry: Entry, preferredSource: String? = nil, save: Bool = false) {
        let entryObject = EntryObject(context: container.viewContext)
        entryObject.set(entry, context: container.viewContext)
        entryObject.preferredSource = preferredSource
        if save {
            self.save()
        }
    }

    func setEntryPreferredSource(mediaType: MediaType, id: String, preferredSource: String, save: Bool = false) {
        if let entry = getEntry(mediaType: mediaType, id: id) {
            entry.preferredSource = preferredSource
            if save {
                self.save()
            }
        }
    }
}
