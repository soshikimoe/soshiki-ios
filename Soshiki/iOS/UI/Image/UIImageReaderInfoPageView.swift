//
//  UIImageReaderInfoPageView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/8/22.
//

import Foundation
import UIKit

class UIImageReaderInfoPageView: UIView {
    let previousChapter: ImageSourceChapter?
    let nextChapter: ImageSourceChapter?

    let previousChapterLabel = UILabel()
    let nextChapterLabel = UILabel()

    init(previous previousChapter: ImageSourceChapter? = nil, next nextChapter: ImageSourceChapter? = nil) {
        self.previousChapter = previousChapter
        self.nextChapter = nextChapter
        super.init(frame: UIScreen.main.bounds)

        if let previousChapter {
            let previousVolumeText = previousChapter.volume != nil && !previousChapter.volume!.isNaN ?
                "Volume \(previousChapter.volume!.toTruncatedString()) " : ""
            let previousChapterNameText = previousChapter.name != nil && !previousChapter.name!.isEmpty ? ": \(previousChapter.name!)" : ""
            previousChapterLabel.text = "\(previousVolumeText)Chapter \(previousChapter.chapter.toTruncatedString())\(previousChapterNameText)"
        } else {
            previousChapterLabel.text = "No previous chapter"
        }
        previousChapterLabel.lineBreakMode = .byTruncatingTail
        let previousChapterTitle = UILabel()
        previousChapterTitle.text = "Previous:"
        previousChapterTitle.font = .boldSystemFont(ofSize: 20)

        if let nextChapter {
            let nextVolumeText = nextChapter.volume != nil && !nextChapter.volume!.isNaN ?
                "Volume \(nextChapter.volume!.toTruncatedString()) " : ""
            let nextChapterNameText = nextChapter.name != nil && !nextChapter.name!.isEmpty ? ": \(nextChapter.name!)" : ""
            nextChapterLabel.text = "\(nextVolumeText)Chapter \(nextChapter.chapter.toTruncatedString())\(nextChapterNameText)"
        } else {
            nextChapterLabel.text = "No next chapter"
        }
        nextChapterLabel.lineBreakMode = .byTruncatingTail
        let nextChapterTitle = UILabel()
        nextChapterTitle.text = "Next:"
        nextChapterTitle.font = .boldSystemFont(ofSize: 20)

        let topStackView = UIStackView()
        topStackView.alignment = .center
        topStackView.axis = .vertical
        topStackView.distribution = .equalSpacing
        topStackView.addArrangedSubview(previousChapterTitle)
        topStackView.addArrangedSubview(previousChapterLabel)

        let bottomStackView = UIStackView()
        bottomStackView.alignment = .center
        bottomStackView.axis = .vertical
        bottomStackView.distribution = .equalSpacing
        bottomStackView.addArrangedSubview(nextChapterTitle)
        bottomStackView.addArrangedSubview(nextChapterLabel)

        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubview(topStackView)
        stackView.addArrangedSubview(bottomStackView)

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
