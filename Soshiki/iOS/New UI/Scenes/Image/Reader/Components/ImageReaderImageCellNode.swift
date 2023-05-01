//
//  ImageReaderImageCellNode.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/21/23.
//

import AsyncDisplayKit
import Nuke

class ImageReaderImageCellNode: ASCellNode {
    let imageNode: ASImageNode
    let progressView: CircularProgressView
    let reloadButton: UIButton

    let pageIndex: Int

    var image: URL?

    var imageTask: ImageTask?

    let readingMode: ImageReaderViewController.ReadingMode

    weak var delegate: (any ImageReaderCellNodeDelegate)?
    weak var resizeDelegate: (any ImageCellNodeResizeDelegate)?

    init(pageIndex: Int, readingMode: ImageReaderViewController.ReadingMode) {
        self.imageNode = ASImageNode()
        self.progressView = CircularProgressView()
        self.reloadButton = UIButton(type: .roundedRect)

        self.pageIndex = pageIndex
        self.readingMode = readingMode

        super.init()

        configureSubviews()
        applyConstraints()
    }

    func configureSubviews() {
        self.shouldAnimateSizeChanges = false
        if self.readingMode.isPaged {
            self.style.preferredSize = UIScreen.main.bounds.size
        }

        self.imageNode.shouldAnimateSizeChanges = false
        self.imageNode.style.preferredSize = UIScreen.main.bounds.size
        self.imageNode.contentMode = self.readingMode.isPaged ? .scaleAspectFit : .scaleAspectFill

        self.progressView.progressColor = .tintColor

        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.progressView)

        self.reloadButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        self.reloadButton.addTarget(self, action: #selector(reloadButtonPressed), for: .touchUpInside)
        self.reloadButton.isHidden = true

        self.reloadButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.reloadButton)

        self.addSubnode(imageNode)
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.progressView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.progressView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.progressView.widthAnchor.constraint(equalToConstant: 40),
            self.progressView.heightAnchor.constraint(equalToConstant: 40),

            self.reloadButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.reloadButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if self.readingMode.isPaged {
            return ASCenterLayoutSpec(centeringOptions: .XY, child: self.imageNode)
        } else {
            return ASWrapperLayoutSpec(layoutElement: self.imageNode)
        }
    }

    func setImage(to url: URL?) {
        self.image = url
    }

    func loadImage() {
        if let image = self.image {
            self.progressView.isHidden = false
            self.reloadButton.isHidden = true
            self.imageNode.isHidden = true
            self.imageTask = ImagePipeline.shared.loadImage(
                with: image,
                progress: { [weak self] _, progress, total in
                    self?.progressView.setProgress(value: Float(progress) / Float(total), withAnimation: false)
                },
                completion: { [weak self] result in
                    if case .success(let response) = result {
                        self?.progressView.isHidden = true
                        self?.reloadButton.isHidden = true
                        self?.imageNode.isHidden = false
                        self?.imageNode.image = response.image

                        let newSize: CGSize
                        if self?.readingMode.isPaged == true, UIScreen.main.bounds.size.aspectRatio > response.image.size.aspectRatio {
                            newSize = CGSize(
                                width: UIScreen.main.bounds.height * response.image.size.aspectRatio,
                                height: UIScreen.main.bounds.height
                            )
                        } else {
                            newSize = CGSize(
                                width: UIScreen.main.bounds.width,
                                height: UIScreen.main.bounds.width / response.image.size.aspectRatio
                            )
                        }

                        self?.imageNode.style.width = ASDimensionMake(newSize.width)
                        self?.imageNode.style.height = ASDimensionMake(newSize.height)

                        if let currentSize = self?.frame.size, let indexPath = self?.indexPath {
                            self?.resizeDelegate?.willResize(
                                from: currentSize,
                                to: newSize,
                                at: indexPath
                            )
                        }

                        self?.imageNode.setNeedsLayout()
                        self?.imageNode.setNeedsDisplay()
                    } else {
                        self?.progressView.isHidden = true
                        self?.imageNode.isHidden = true
                        self?.reloadButton.isHidden = false
                    }
                }
            )
        }
    }

    @objc func reloadButtonPressed() {
        loadImage()
    }
}

// MARK: - View Callbacks

extension ImageReaderImageCellNode {
    override func didEnterDisplayState() {
        super.didEnterDisplayState()
        self.loadImage()
    }

    override func didExitDisplayState() {
        super.didExitDisplayState()
        self.imageTask?.cancel()
    }

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
