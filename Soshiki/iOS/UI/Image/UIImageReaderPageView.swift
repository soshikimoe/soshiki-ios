//
//  ImageReaderPageView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 12/4/22.
//

import Nuke
import UIKit

class UIImageReaderPageView: UIView {
    let progressView = UICircularProgressView(frame: .init(x: 0, y: 0, width: 40, height: 40))
    let imageView = UIImageView(frame: UIScreen.main.bounds)
    let zoomableView = UIZoomableView(frame: UIScreen.main.bounds)
    let reloadButton = UIButton(frame: .init(x: 0, y: 0, width: 40, height: 40))

    var image: String?
    var source: ImageSource

    init(_ image: String? = nil, source: ImageSource) {
        self.image = image
        self.source = source
        super.init(frame: UIScreen.main.bounds)

        imageView.contentMode = .scaleAspectFit
        zoomableView.addSubview(imageView)
        zoomableView.zoomView = imageView
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: zoomableView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: zoomableView.trailingAnchor).isActive = true
//        imageView.centerXAnchor.constraint(equalTo: zoomableView.centerXAnchor).isActive = true
//        imageView.centerYAnchor.constraint(equalTo: zoomableView.centerYAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: zoomableView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: zoomableView.bottomAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: zoomableView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: zoomableView.heightAnchor).isActive = true
        addSubview(zoomableView)
        zoomableView.translatesAutoresizingMaskIntoConstraints = false
        zoomableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        zoomableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        zoomableView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        zoomableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        reloadButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        reloadButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        if let image {
            setImage(image)
        }
    }

    func setImage(_ image: String) {
        self.image = image
        imageView.alpha = 0
        progressView.alpha = 1
        reloadButton.alpha = 0
        Task {
            let request = ImageRequest(url: URL(string: image))
            ImagePipeline.shared.loadImage(
                with: await source.modifyImageRequest(request: request) ?? request,
                progress: { [weak self] _, progress, total in
                    guard let self else { return }
                    self.progressView.setProgress(value: Float(progress) / Float(total), withAnimation: true)
                },
                completion: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let response):
                        self.imageView.image = response.image
                        self.imageView.alpha = 1
                        self.progressView.alpha = 0
                        self.reloadButton.alpha = 0
                    case .failure:
                        self.imageView.alpha = 0
                        self.progressView.alpha = 0
                        self.reloadButton.alpha = 1
                    }
                }
            )
        }
    }

    @objc func reload() {
        guard let image else { return }
        setImage(image)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
