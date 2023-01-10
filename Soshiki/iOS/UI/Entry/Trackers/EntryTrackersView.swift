//
//  EntryTrackersView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/9/23.
//

import SwiftUI

struct EntryTrackersView: View {
    @EnvironmentObject var trackerManager: TrackerManager

    var entry: Entry

    var body: some View {
        NavigationStack {
            List(trackerManager.trackers.filter({ tracker in
                entry.trackers.contains(where: { $0.id == tracker.id })
            }), id: \.id) { tracker in
                EntryTrackerView(entry: entry, tracker: tracker)
            }.navigationTitle("Trackers")
        }
    }
}
