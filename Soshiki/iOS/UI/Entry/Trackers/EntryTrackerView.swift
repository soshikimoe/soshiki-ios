//
//  EntryTrackerView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/9/23.
//

import SwiftUI

struct EntryTrackerView: View {
    var entry: Entry
    var tracker: Tracker

    @AppStorage var isTracking: Bool

    @State var deleteAlertPresented = false

    @State var importAlertPresented = false

    init(entry: Entry, tracker: Tracker) {
        self.entry = entry
        self.tracker = tracker
        self._isTracking = AppStorage(
            wrappedValue: UserDefaults.standard.bool(forKey: "settings.tracker.\(tracker.id).automaticallyTrack"),
            "user.trackers.\(tracker.id).\(entry._id).isTracking"
        )
    }

    var body: some View {
        HStack {
            if let uiImage = UIImage(contentsOfFile: tracker.image.path()) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading) {
                Text(tracker.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(tracker.author)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $isTracking)
        }.onChange(of: isTracking) { newValue in
            if newValue {
                importAlertPresented = true
            } else {
                deleteAlertPresented = true
            }
        }.alert("Tracker Disabled", isPresented: $deleteAlertPresented) {
            Button("Yes", role: .destructive) {
                if let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId {
                    Task {
                        await tracker.deleteHistory(mediaType: entry.mediaType, id: entryId)
                    }
                }
            }
            Button("No", role: .cancel) {}
        } message: {
            Text("Would you like to delete the tracking data?")
        }.alert("Tracker Enabled", isPresented: $importAlertPresented) {
            Button("Push") {
                Task {
                    if let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId,
                       let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                        await tracker.setHistory(mediaType: entry.mediaType, id: entryId, history: history)
                    }
                }
            }
            Button("Pull") {
                Task {
                    if let entryId = entry.trackers.first(where: { $0.id == tracker.id })?.entryId,
                       let history = await tracker.getHistory(mediaType: entry.mediaType, id: entryId) {
                        var query: [SoshikiAPI.HistoryQuery] = [.status(history.status)]
                        if let page = history.page { query.append(.page(page)) }
                        if let chapter = history.chapter { query.append(.chapter(chapter)) }
                        if let volume = history.volume { query.append(.volume(volume)) }
                        if let timestamp = history.timestamp { query.append(.timestamp(timestamp)) }
                        if let episode = history.episode { query.append(.episode(episode)) }
                        if let score = history.score { query.append(.score(score)) }
                        await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: query)
                    }
                }
            }
        } message: {
            Text("Would you like to try to pull information from the tracker if present, or push current information to it?")
        }
    }
}
