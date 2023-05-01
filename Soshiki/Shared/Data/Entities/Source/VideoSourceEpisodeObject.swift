//
//  VideoSourceEpisodeObject.swift
//  Soshiki
//
//  Created by Jim Phieffer on 2/4/23.
//

import CoreData

@objc(VideoSourceEpisodeObject)
class VideoSourceEpisodeObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<VideoSourceEpisodeObject> {
        NSFetchRequest(entityName: "VideoSourceEpisode")
    }

    @NSManaged var entryId: String
    @NSManaged var episode: Double
    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var type: String

    func set(_ videoSourceEpisode: VideoSourceEpisode, context: NSManagedObjectContext) {
        self.entryId = videoSourceEpisode.entryId
        self.episode = videoSourceEpisode.episode
        self.id = videoSourceEpisode.id
        self.name = videoSourceEpisode.name
        self.type = videoSourceEpisode.type.rawValue
    }

//    func get() -> VideoSourceEpisode {
//        VideoSourceEpisode(
//            id: id,
//            entryId: entryId,
//            name: name,
//            episode: episode,
//            type: VideoSourceEpisodeType(rawValue: type) ?? .unknown
//        )
//    }
}

@objc(VideoSourceEpisodeDetailsObject)
class VideoSourceEpisodeDetailsObject: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<VideoSourceEpisodeDetailsObject> {
        NSFetchRequest(entityName: "VideoSourceEpisodeDetails")
    }

    @NSManaged var entryId: String
    @NSManaged var id: String

    @NSManaged var providers: NSOrderedSet

    func set(_ videoSourceEpisodeDetails: VideoSourceEpisodeDetails, context: NSManagedObjectContext) {
        self.id = videoSourceEpisodeDetails.id
        self.entryId = videoSourceEpisodeDetails.entryId
        for provider in videoSourceEpisodeDetails.providers {
            if let providerObject = providers.compactMap({ $0 as? VideoSourceEpisodeProviderObject }).first(where: {
                $0.name == provider.name
            }) {
                providerObject.set(provider, context: context)
            } else {
                let providerObject = VideoSourceEpisodeProviderObject(context: context)
                providerObject.set(provider, context: context)
                addToProviders(providerObject)
            }
        }
        providers.compactMap({ $0 as? VideoSourceEpisodeProviderObject }).forEach({ providerObject in
            if !videoSourceEpisodeDetails.providers.contains(where: {
                providerObject.name == $0.name
            }) {
                removeFromProviders(providerObject)
            }
        })
    }

    func get() -> VideoSourceEpisodeDetails {
        VideoSourceEpisodeDetails(
            id: id,
            entryId: entryId,
            providers: providers.compactMap({ ($0 as? VideoSourceEpisodeProviderObject)?.get() })
        )
    }
}

extension VideoSourceEpisodeDetailsObject {
    @objc(addProvidersObject:)
    @NSManaged func addToProviders(_ value: VideoSourceEpisodeProviderObject)
    @objc(removeProvidersObject:)
    @NSManaged func removeFromProviders(_ value: VideoSourceEpisodeProviderObject)
    @objc(addProviders:)
    @NSManaged func addToProviders(_ values: NSOrderedSet)
    @objc(removeProviders:)
    @NSManaged func removeFromProviders(_ values: NSOrderedSet)
}

@objc(VideoSourceEpisodeProviderObject)
class VideoSourceEpisodeProviderObject: NSManagedObject {
    @NSManaged var name: String

    @NSManaged var urls: NSOrderedSet

    func set(_ videoSourceEpisodeProvider: VideoSourceEpisodeProvider, context: NSManagedObjectContext) {
        self.name = videoSourceEpisodeProvider.name
        for url in videoSourceEpisodeProvider.urls {
            if let urlObject = urls.compactMap({ $0 as? VideoSourceEpisodeUrlObject }).first(where: {
                ($0.quality == -1 ? nil : $0.quality) == url.quality && $0.url == url.url && $0.type == url.type.rawValue
            }) {
                urlObject.set(url, context: context)
            } else {
                let urlObject = VideoSourceEpisodeUrlObject(context: context)
                urlObject.set(url, context: context)
                addToUrls(urlObject)
            }
        }
        urls.compactMap({ $0 as? VideoSourceEpisodeUrlObject }).forEach({ urlObject in
            if !videoSourceEpisodeProvider.urls.contains(where: {
                (urlObject.quality == -1 ? nil : urlObject.quality) == $0.quality && urlObject.url == $0.url && urlObject.type == $0.type.rawValue
            }) {
                removeFromUrls(urlObject)
            }
        })
    }

    func get() -> VideoSourceEpisodeProvider {
        VideoSourceEpisodeProvider(
            name: name,
            urls: urls.compactMap({ ($0 as? VideoSourceEpisodeUrlObject)?.get() })
        )
    }
}

extension VideoSourceEpisodeProviderObject {
    @objc(addUrlsObject:)
    @NSManaged func addToUrls(_ value: VideoSourceEpisodeUrlObject)
    @objc(removeUrlsObject:)
    @NSManaged func removeFromUrls(_ value: VideoSourceEpisodeUrlObject)
    @objc(addUrls:)
    @NSManaged func addToUrls(_ values: NSOrderedSet)
    @objc(removeUrls:)
    @NSManaged func removeFromUrls(_ values: NSOrderedSet)
}

@objc(VideoSourceEpisodeUrlObject)
class VideoSourceEpisodeUrlObject: NSManagedObject {
    @NSManaged var quality: Double
    @NSManaged var type: String
    @NSManaged var url: String

    func set(_ videoSourceEpisodeUrl: VideoSourceEpisodeUrl, context: NSManagedObjectContext) {
        self.quality = videoSourceEpisodeUrl.quality ?? -1
        self.type = videoSourceEpisodeUrl.type.rawValue
        self.url = videoSourceEpisodeUrl.url
    }

    func get() -> VideoSourceEpisodeUrl {
        VideoSourceEpisodeUrl(
            type: VideoSourceEpisodeUrlType(rawValue: type) ?? .video,
            url: url,
            quality: quality == -1 ? nil : quality
        )
    }
}
