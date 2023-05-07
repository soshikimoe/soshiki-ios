//
//  TextReaderViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 1/15/23.
//

import UIKit
import WebKit

class TextReaderViewController: UIViewController {
    var observers: [NSObjectProtocol] = []

    var fontSize = UserDefaults.standard.object(forKey: "settings.text.fontSize") as? Double ?? 40
    var margin = UserDefaults.standard.object(forKey: "settings.text.margin") as? Double ?? 80
    var font = UserDefaults.standard.string(forKey: "settings.text.font") ?? "Georgia"
    var fontColor = UserDefaults.standard.string(forKey: "settings.text.fontColor").flatMap({ UIColor.from(rawValue: $0) }) ?? .label
    var backgroundColor = UserDefaults.standard.string(forKey: "settings.text.backgroundColor").flatMap({
        UIColor.from(rawValue: $0)
    }) ?? .systemBackground

    var chapters: [TextSourceChapter]
    var source: any TextSource
    var entry: Entry?
    var history: History?

    var chapter: Int {
        didSet {
            chapterLabel.text = chapters[safe: chapter].flatMap({ $0.chapter.isNaN ? nil : "Chapter \($0.chapter.toTruncatedString())" })
            volumeLabel.text = chapters[safe: chapter]?.volume.flatMap({ $0.isNaN ? nil : "Volume \($0.toTruncatedString())" })
        }
    }

    var details: TextSourceChapterDetails?
    var previousDetails: TextSourceChapterDetails?
    var nextDetails: TextSourceChapterDetails?

    let chapterLabel = UILabel()
    let volumeLabel = UILabel()

    let webView: WKWebView

    lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        single.numberOfTapsRequired = 1
        single.delegate = self
        return single
    }()

    var percent: Double {
        round(
            webView.scrollView.contentOffset.y / max(
                webView.scrollView.contentSize.height - view.bounds.height,
                webView.scrollView.contentOffset.y
            ) * CGFloat(100)
        ).clamped(to: CGFloat(0)...CGFloat(100))
    }

    init(chapters: [TextSourceChapter], chapter: Int, source: any TextSource, entry: Entry?, history: History?) {
        self.chapters = chapters
        self.chapter = chapter
        self.source = source
        self.entry = entry
        self.history = history

        let userScript = WKUserScript(
            source: """
                document.documentElement.style.setProperty('font-size', '\(self.fontSize.toTruncatedString())px');
                document.documentElement.style.setProperty('padding', '\(self.margin.toTruncatedString())px');
                document.documentElement.style.setProperty('font-family', "'\(self.font)'");
                document.documentElement.style.setProperty('color', '#\(self.fontColor.hex ?? "000")');
                document.documentElement.style.setProperty('background-color', '#\(self.backgroundColor.hex ?? "fff")');
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.scrollView.showsHorizontalScrollIndicator = false
        self.webView.scrollView.showsVerticalScrollIndicator = false

        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
        self.navigationItem.hidesBackButton = true
        self.navigationItem.largeTitleDisplayMode = .never

        volumeLabel.font = .systemFont(ofSize: 12)
        volumeLabel.textColor = .secondaryLabel

        let chapterVolumeStackView = UIStackView(arrangedSubviews: [ volumeLabel, chapterLabel ])
        chapterVolumeStackView.alignment = .center
        chapterVolumeStackView.axis = .vertical
        chapterVolumeStackView.distribution = .equalCentering
        self.navigationItem.titleView = chapterVolumeStackView

        let closeReaderButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeReader)
        )
        let previousChapterButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(previousChapter)
        )
        let nextChapterButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(nextChapter)
        )
        let openSettingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)
        )

        self.navigationItem.leftBarButtonItems = [ closeReaderButton, previousChapterButton ]
        self.navigationItem.rightBarButtonItems = [ openSettingsButton, nextChapterButton ]

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.fontSize"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.fontSize = UserDefaults.standard.object(forKey: "settings.text.fontSize") as? Double ?? 40
                self.webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('font-size', '\(self.fontSize.toTruncatedString())px');"
                )
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.margin"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.margin = UserDefaults.standard.object(forKey: "settings.text.margin") as? Double ?? 80
                self.webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('padding', '\(self.margin.toTruncatedString())px');"
                )
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.font"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.font = UserDefaults.standard.string(forKey: "settings.text.font") ?? "Georgia"
                self.webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('font-family', \"'\(self.font)'\");"
                )
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.fontColor"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.fontColor = UserDefaults.standard.string(forKey: "settings.text.fontColor").flatMap({ UIColor.from(rawValue: $0) }) ?? .label
                self.webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('color', '#\(self.fontColor.hex ?? "000")');"
                )
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.text.backgroundColor"), object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.backgroundColor = UserDefaults.standard.string(forKey: "settings.text.backgroundColor").flatMap({
                    UIColor.from(rawValue: $0)
                }) ?? .systemBackground
                self.webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('background-color', '#\(self.backgroundColor.hex ?? "fff")');"
                )
            }
        )

        Task {
            await setChapter(to: chapter)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func loadView() {
        self.view = webView
        self.view.addGestureRecognizer(singleTapGestureRecognizer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = backgroundColor
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = defaultAppearance
        self.navigationController?.navigationBar.compactAppearance = defaultAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = transparentAppearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = transparentAppearance
    }

    func setChapter(to chapter: Int) async {
        guard chapters.indices.contains(chapter) else { return }
        if chapter == self.chapter - 1,
           let nextDetails,
           nextDetails.id == chapters[chapter].id {
            previousDetails = details
            details = nextDetails
            if let nextChapter = chapters[safe: chapter - 1] {
                Task {
                    self.nextDetails = await source.getChapterDetails(id: nextChapter.id, entryId: nextChapter.entryId)
                }
            }
        } else if chapter == self.chapter + 1,
                  let previousDetails,
                  previousDetails.id == chapters[chapter].id {
            nextDetails = details
            details = previousDetails
            if let previousChapter = chapters[safe: chapter + 1] {
                Task {
                    self.previousDetails = await source.getChapterDetails(id: previousChapter.id, entryId: previousChapter.entryId)
                }
            }
        } else {
            let chapters = chapters
            details = await source.getChapterDetails(id: chapters[chapter].id, entryId: chapters[chapter].entryId)
            if let previousChapter = chapters[safe: chapter + 1] {
                Task {
                    self.previousDetails = await source.getChapterDetails(id: previousChapter.id, entryId: previousChapter.entryId)
                }
            }
            if let nextChapter = chapters[safe: chapter - 1] {
                Task {
                    self.nextDetails = await source.getChapterDetails(id: nextChapter.id, entryId: nextChapter.entryId)
                }
            }
        }
        self.chapter = chapter
        if let details {
            self.webView.loadHTMLString(details.html, baseURL: details.baseUrl.flatMap({ URL(string: $0) }))
        }
    }
}

extension TextReaderViewController {
    @objc func previousChapter() {
        Task {
            await setChapter(to: chapter + 1)
        }
    }

    @objc func nextChapter() {
        Task {
            await setChapter(to: chapter - 1)
        }
    }

    @objc func openSettings() {
        self.navigationController?.pushViewController(TextReaderSettingsViewController(), animated: true)
    }

    @objc func closeReader() {
        Task {
            if let entry = entry {
                await SoshikiAPI.shared.setHistory(
                    mediaType: entry.mediaType,
                    id: entry._id,
                    query: [
                        .percent(percent),
                        .chapter(chapters[chapter].chapter)
                    ] + (chapters[chapter].volume.flatMap({
                        [ .volume($0) ] as [SoshikiAPI.HistoryQuery]
                    }) ?? [])
                )
                if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                    await TrackerManager.shared.setHistory(entry: entry, history: history)
                }
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
}

extension TextReaderViewController {
    @objc func singleTap() {
        if self.navigationController?.navigationBar.isHidden == true {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 1
            }
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 0
            } completion: { _ in
                self.navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
    }
}

extension TextReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
