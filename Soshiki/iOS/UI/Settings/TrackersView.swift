//
//  TrackersView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/8/23.
//

import SwiftUI

struct TrackersView: View {
    @EnvironmentObject var trackerManager: TrackerManager

    @State var addTrackerAlertPresented = false
    @State var addTrackerAlertTextContent = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(trackerManager.trackers, id: \.id) { tracker in
                    NavigationLink {
                        TrackerView(tracker: tracker)
                    } label: {
                        TrackerCardView(tracker: tracker)
                    }
                }.onDelete(perform: deleteTracker)
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addTrackerAlertPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }.alert("Install a Tracker", isPresented: $addTrackerAlertPresented) {
                TextField("Tracker URL", text: $addTrackerAlertTextContent)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                Button("Install", role: .cancel) {
                    if let url = URL(string: addTrackerAlertTextContent), url.pathExtension == "soshikitracker" {
                        Task {
                            await trackerManager.installTracker(url)
                        }
                    }
                    addTrackerAlertTextContent = ""
                }
            } message: {
                Text("Enter a tracker URL below to install it.")
            }.navigationTitle("Trackers")
        }
    }

    func deleteTracker(at offsets: IndexSet) {
        for offset in offsets {
            trackerManager.removeTracker(id: trackerManager.trackers[offset].id)
        }
    }
}
