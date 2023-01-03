//
//  ImageReaderSettingsView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/31/22.
//

import SwiftUI

struct ImageReaderSettingsView: View {
    @ObservedObject var imageReaderViewModel: ImageReaderViewModel

    var body: some View {
        Form {
            Section("General") {
                Picker("Reading Mode", selection: $imageReaderViewModel.readingMode) {
                    ForEach(ReadingMode.allCases, id: \.rawValue) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                HStack {
                    Text("Pages to Preload")
                    Spacer()
                    InlineStepper(
                        value: Binding(get: { Float(imageReaderViewModel.pagesToPreload) }, set: { imageReaderViewModel.pagesToPreload = Int($0) }),
                        lowerBound: 1,
                        upperBound: 5,
                        step: 1,
                        allowsCustomInput: true
                    )
                }
            }
        }
    }
}
