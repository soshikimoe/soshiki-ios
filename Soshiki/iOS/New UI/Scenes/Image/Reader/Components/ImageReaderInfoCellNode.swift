//
//  ImageReaderInfoCellNode.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/21/23.
//

import AsyncDisplayKit

class ImageReaderInfoCellNode: ASCellNode {
    let previousChapterTitleLabel: UILabel
    let previousChapterTextLabel: UILabel
    let previousChapterImageView: UIImageView
    let nextChapterTitleLabel: UILabel
    let nextChapterTextLabel: UILabel
    let nextChapterImageView: UIImageView

    let previousChapterStackView: UIStackView
    let nextChapterStackView: UIStackView

    let previousChapter: ImageSourceChapter?
    let nextChapter: ImageSourceChapter?
    let readingMode: ImageReaderViewController.ReadingMode

    weak var delegate: (any ImageReaderCellNodeDelegate)?

    init(
        previous previousChapter: ImageSourceChapter? = nil,
        next nextChapter: ImageSourceChapter? = nil,
        readingMode: ImageReaderViewController.ReadingMode
    ) {
        self.previousChapterTitleLabel = UILabel()
        self.previousChapterTextLabel = UILabel()
        self.previousChapterImageView = UIImageView()
        self.nextChapterTitleLabel = UILabel()
        self.nextChapterTextLabel = UILabel()
        self.nextChapterImageView = UIImageView()

        self.previousChapterStackView = UIStackView()
        self.nextChapterStackView = UIStackView()

        self.previousChapter = previousChapter
        self.nextChapter = nextChapter
        self.readingMode = readingMode

        super.init()

        configureSubviews()
        applyConstraints()
    }

    func configureSubviews() {
        self.previousChapterTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.previousChapterTitleLabel.text = "Previous Chapter"

        self.previousChapterTextLabel.font = .systemFont(ofSize: 18)
        if let previousChapter = self.previousChapter {
            self.previousChapterTextLabel.text = previousChapter.toListString()
        } else {
            self.previousChapterTextLabel.text = "No Previous Chapter"
        }

        self.previousChapterStackView.axis = .vertical
        self.previousChapterStackView.spacing = 4
        self.previousChapterStackView.alignment = .center
        self.previousChapterStackView.addArrangedSubview(self.previousChapterTitleLabel)
        self.previousChapterStackView.addArrangedSubview(self.previousChapterTextLabel)

        self.nextChapterTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        self.nextChapterTitleLabel.text = "Next Chapter"

        self.nextChapterTextLabel.font = .systemFont(ofSize: 18)
        if let nextChapter = self.nextChapter {
            self.nextChapterTextLabel.text = nextChapter.toListString()
        } else {
            self.nextChapterTextLabel.text = "No Next Chapter"
        }

        self.nextChapterStackView.axis = .vertical
        self.nextChapterStackView.spacing = 4
        self.nextChapterStackView.alignment = .center
        self.nextChapterStackView.addArrangedSubview(self.nextChapterTitleLabel)
        self.nextChapterStackView.addArrangedSubview(self.nextChapterTextLabel)

        if self.readingMode.scrollDirection == .vertical { // Next chapter is below
            self.previousChapterImageView.image = UIImage(systemName: "chevron.compact.up")
            self.nextChapterImageView.image = UIImage(systemName: "chevron.compact.down")
        } else if self.readingMode.isReversed { // Next chapter is to the left
            self.previousChapterImageView.image = UIImage(systemName: "chevron.compact.right")
            self.nextChapterImageView.image = UIImage(systemName: "chevron.compact.left")
        } else { // Next chapter is to the right
            self.previousChapterImageView.image = UIImage(systemName: "chevron.compact.left")
            self.nextChapterImageView.image = UIImage(systemName: "chevron.compact.right")
        }

        if self.previousChapter != nil {
            self.previousChapterImageView.tintColor = .label
        } else {
            self.previousChapterImageView.tintColor = .secondaryLabel
        }

        if self.nextChapter != nil {
            self.nextChapterImageView.tintColor = .label
        } else {
            self.nextChapterImageView.tintColor = .secondaryLabel
        }

        self.previousChapterImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
        self.nextChapterImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)

        self.previousChapterStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previousChapterStackView)

        self.nextChapterStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.nextChapterStackView)

        self.previousChapterImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previousChapterImageView)

        self.nextChapterImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.nextChapterImageView)

        self.style.preferredSize = CGSize(
            width: UIScreen.main.bounds.width,
            height: self.readingMode.isPaged ? UIScreen.main.bounds.height : UIScreen.main.bounds.height / 2
        )
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.previousChapterStackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor, constant: -48),
            self.previousChapterStackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 72),
            self.previousChapterStackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -72),

            self.nextChapterStackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor, constant: 48),
            self.nextChapterStackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 72),
            self.nextChapterStackView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -72)
        ])

        if self.readingMode.scrollDirection == .vertical {
            NSLayoutConstraint.activate([
                self.previousChapterImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.previousChapterImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 4),

                self.nextChapterImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.nextChapterImageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -4)
            ])
        } else if self.readingMode.isReversed {
            NSLayoutConstraint.activate([
                self.previousChapterImageView.centerYAnchor.constraint(equalTo: self.previousChapterStackView.centerYAnchor),
                self.previousChapterImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

                self.nextChapterImageView.centerYAnchor.constraint(equalTo: self.nextChapterStackView.centerYAnchor),
                self.nextChapterImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
            ])
        } else {
            NSLayoutConstraint.activate([
                self.previousChapterImageView.centerYAnchor.constraint(equalTo: self.previousChapterStackView.centerYAnchor),
                self.previousChapterImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

                self.nextChapterImageView.centerYAnchor.constraint(equalTo: self.nextChapterStackView.centerYAnchor),
                self.nextChapterImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            ])
        }
    }
}

// MARK: - View Callbacks

extension ImageReaderInfoCellNode {
    override func didEnterVisibleState() {
        super.didEnterVisibleState()

        if let indexPath = self.indexPath {
            self.delegate?.didEnterVisibleState?(at: indexPath)
        }
    }

    override func didExitVisibleState() {
        super.didExitVisibleState()

        if let indexPath = self.indexPath {
            self.delegate?.didExitVisibleState?(at: indexPath)
        }
    }
}
