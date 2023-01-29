//
//  ImageReaderViewController.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/20/22.
//

import UIKit
import Nuke

class ImageReaderViewController: UIPageViewController {
    var observers: [NSObjectProtocol] = []

    var pagesToPreload = UserDefaults.standard.object(forKey: "settings.image.pagesToPreload") as? Int ?? 3
    var readingMode = UserDefaults.standard.string(forKey: "settings.image.readingMode").flatMap({ ReadingMode(rawValue: $0) }) ?? .rtl {
        didSet {
            Task {
                await self.setChapter(to: chapter, direction: .none)
            }
        }
    }

    var chapters: [ImageSourceChapter]
    var chapter: Int {
        didSet {
            chapterLabel.text = chapters[safe: chapter].flatMap({ $0.chapter.isNaN ? nil : "Chapter \($0.chapter.toTruncatedString())" })
            volumeLabel.text = chapters[safe: chapter]?.volume.flatMap({ $0.isNaN ? nil : "Volume \($0.toTruncatedString())" })
        }
    }

    var page = 0 {
        didSet {
            pageLabel.text = pages.indices.contains(page) ? "Page \(page + 1) of \(pages.count)" : nil
        }
    }

    var source: any ImageSource
    var entry: Entry?
    var history: History?

    var pages: [String] = [] {
        didSet {
            pageLabel.text = pages.indices.contains(page) ? "Page \(page + 1) of \(pages.count)" : nil
        }
    }

    var pageViewControllers: [UIViewController] = []

    var previousDetails: ImageSourceChapterDetails?
    var details: ImageSourceChapterDetails?
    var nextDetails: ImageSourceChapterDetails?

    var hasPreviousChapter: Bool { chapter < chapters.count - 1 }
    var hasNextChapter: Bool { chapter > 0 }

    let volumeLabel = UILabel()
    let chapterLabel = UILabel()
    let pageLabel = UILabel()

    lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        single.numberOfTapsRequired = 1
        return single
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(chapters: [ImageSourceChapter], chapter: Int, source: any ImageSource, entry: Entry?, history: History?) {
        self.chapters = chapters
        self.chapter = chapter
        self.source = source
        self.entry = entry
        self.history = history
        if let page = history?.page {
            self.page = page - 1
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        self.dataSource = self
        self.delegate = self

        self.view.backgroundColor = .systemBackground
        self.hidesBottomBarWhenPushed = true
        self.navigationItem.hidesBackButton = true
        self.navigationItem.largeTitleDisplayMode = .never

        self.view.addGestureRecognizer(singleTapGestureRecognizer)

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
        let leftPageButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(leftPage)
        )
        let leftSpacer = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace, target: nil, action: nil
        )
        pageLabel.text = ""
        let pageLabel = UIBarButtonItem(customView: pageLabel)
        let rightSpacer = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace, target: nil, action: nil
        )
        let rightPageButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(rightPage)
        )

        self.navigationItem.leftBarButtonItems = [ closeReaderButton, previousChapterButton ]
        self.navigationItem.rightBarButtonItems = [ openSettingsButton, nextChapterButton ]

        self.toolbarItems = [ leftPageButton, leftSpacer, pageLabel, rightSpacer, rightPageButton ]

        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.image.pagesToPreload"), object: nil, queue: nil) { [weak self] _ in
                self?.pagesToPreload = UserDefaults.standard.object(forKey: "settings.image.pagesToPreload") as? Int ?? 3
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: .init("settings.image.readingMode"), object: nil, queue: nil) { [weak self] _ in
                self?.readingMode = UserDefaults.standard.string(forKey: "settings.image.readingMode").flatMap({ ReadingMode(rawValue: $0) }) ?? .rtl
            }
        )
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await self.setChapter(to: chapter, direction: .none)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
        let transparentAppearance = UINavigationBarAppearance()
        transparentAppearance.configureWithTransparentBackground()
        let defaultAppearance = UINavigationBarAppearance()
        defaultAppearance.configureWithDefaultBackground()
        self.navigationController?.navigationBar.standardAppearance = defaultAppearance
        self.navigationController?.navigationBar.compactAppearance = defaultAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = transparentAppearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = transparentAppearance
    }

    func loadPages(_ range: Range<Int>) {
        for index in range {
            guard let pageView = pageViewControllers[
                safe: self.readingMode == .rtl
                    ? (pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2))
                    : (index + (hasPreviousChapter ? 2 : 1))
            ]?.view as? ImageReaderPageView,
                  pageView.imageView.image == nil,
                  let page = pages[safe: index] else { continue }
            pageView.setImage(page)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func setChapter(to chapterIndex: Int, direction: Direction) async {
        if let chapter = self.chapters[safe: chapterIndex] {
            let details: ImageSourceChapterDetails!
            if let previousDetails, previousDetails.id == chapter.id {
                nextDetails = self.details
                details = previousDetails
                Task { [weak self] in
                    guard let self, let previousChapter = self.chapters[safe: chapterIndex + 1] else { return }
                    self.previousDetails = await self.source.getChapterDetails(
                        id: previousChapter.id, entryId: previousChapter.entryId
                    )
                    if let preloadedPageView = pageViewControllers[
                        safe: self.readingMode == .rtl ? pageViewControllers.count - 1 : 0
                    ]?.view as? ImageReaderPageView,
                       let lastPage = self.previousDetails?.pages.last?.url {
                        preloadedPageView.setImage(lastPage)
                    }
                }
            } else if let nextDetails, nextDetails.id == chapter.id {
                previousDetails = self.details
                details = nextDetails
                Task { [weak self] in
                    guard let self, let nextChapter = self.chapters[safe: chapterIndex - 1] else { return }
                    self.nextDetails = await self.source.getChapterDetails(
                        id: nextChapter.id, entryId: nextChapter.entryId
                    )
                    if let preloadedPageView = pageViewControllers[
                        safe: self.readingMode == .rtl ? 0 : pageViewControllers.count - 1
                    ]?.view as? ImageReaderPageView,
                       let firstPage = self.nextDetails?.pages.first?.url {
                        preloadedPageView.setImage(firstPage)
                    }
                }
            } else {
                guard let fetchedDetails = await self.source.getChapterDetails(
                    id: chapter.id,
                    entryId: chapter.entryId
                ) else { return }
                details = fetchedDetails
                Task { [weak self] in
                    guard let self else { return }
                    if let previousChapter = self.chapters[safe: chapterIndex + 1] {
                        self.previousDetails = await self.source.getChapterDetails(
                            id: previousChapter.id, entryId: previousChapter.entryId
                        )
                        if let preloadedPageView = pageViewControllers[
                            safe: self.readingMode == .rtl ? pageViewControllers.count - 1 : 0
                        ]?.view as? ImageReaderPageView,
                           let lastPage = self.previousDetails?.pages.last?.url {
                            preloadedPageView.setImage(lastPage)
                        }
                    }
                    if let nextChapter = self.chapters[safe: chapterIndex - 1] {
                        self.nextDetails = await self.source.getChapterDetails(
                            id: nextChapter.id, entryId: nextChapter.entryId
                        )
                        if let preloadedPageView = pageViewControllers[
                            safe: self.readingMode == .rtl ? 0 : pageViewControllers.count - 1
                        ]?.view as? ImageReaderPageView,
                           let firstPage = self.nextDetails?.pages.first?.url {
                            preloadedPageView.setImage(firstPage)
                        }
                    }
                }
            }

            self.pages = details.pages.compactMap({ $0.url })
            self.chapter = chapterIndex
            self.details = details

            if direction == .none {
                pageViewControllers = []
                if self.readingMode == .rtl ? hasNextChapter : hasPreviousChapter {
                    pageViewControllers.append(UIViewController(ImageReaderPageView(source: self.source)))
                }
                pageViewControllers.append(UIViewController(ImageReaderInfoPageView(
                    previous: self.readingMode == .rtl ? chapter : self.chapters[safe: self.chapter + 1],
                    next: self.readingMode == .rtl ? self.chapters[safe: self.chapter + 1] : chapter
                )))
                for _ in 0..<pages.count {
                    pageViewControllers.append(UIViewController(ImageReaderPageView(source: self.source)))
                }
                pageViewControllers.append(UIViewController(ImageReaderInfoPageView(
                    previous: self.readingMode == .rtl ? self.chapters[safe: self.chapter + 1] : chapter,
                    next: self.readingMode == .rtl ? chapter : self.chapters[safe: self.chapter - 1]
                )))
                if self.readingMode == .rtl ? hasPreviousChapter : hasNextChapter {
                    pageViewControllers.append(UIViewController(ImageReaderPageView(source: self.source)))
                }
                self.setViewControllers([pageViewControllers[
                    self.readingMode == .rtl
                        ? pageViewControllers.count - self.page - (hasPreviousChapter ? 3 : 2)
                        : self.page + (hasPreviousChapter ? 2 : 1)
                ]], direction: .forward, animated: false)
                loadPages((self.page - self.pagesToPreload)..<(self.page + self.pagesToPreload + 1))
            } else if (direction == .forward) == (self.readingMode == .ltr) { // if forward in ltr, or backward in rtl
                for viewController in pageViewControllers.dropLast(3) {
                    viewController.view.removeFromSuperview()
                    viewController.removeFromParent()
                }
                pageViewControllers.removeFirst(pageViewControllers.count - 3)
                (pageViewControllers[safe: 2]?.view as? ImageReaderPageView)?.setImage(pages[self.readingMode == .rtl ? pages.count - 1 : 0])
                for _ in 0..<(pages.count - 1) {
                    pageViewControllers.append(UIViewController(ImageReaderPageView(source: self.source)))
                }
                pageViewControllers.append(UIViewController(ImageReaderInfoPageView(
                    previous: self.readingMode == .rtl ? self.chapters[safe: self.chapter + 1] : chapter,
                    next: self.readingMode == .rtl ? chapter : self.chapters[safe: self.chapter - 1]
                )))
                if self.readingMode == .rtl ? hasPreviousChapter : hasNextChapter {
                    pageViewControllers.append(UIViewController(ImageReaderPageView(source: self.source)))
                }
                self.setViewControllers([pageViewControllers[2]], direction: .forward, animated: false)
                self.page = self.readingMode == .rtl ? details.pages.count - 1 : 0
                if self.readingMode == .rtl {
                    loadPages((self.page - self.pagesToPreload)..<(self.page + 1 + 1))
                } else {
                    loadPages((self.page - 1)..<(self.page + self.pagesToPreload + 1))
                }
            } else if (direction == .backward) == (self.readingMode == .ltr) { // if backward in ltr, or forward in rtl
                for viewController in pageViewControllers.dropFirst(3) {
                    viewController.view.removeFromSuperview()
                    viewController.removeFromParent()
                }
                pageViewControllers.removeLast(pageViewControllers.count - 3)
                (pageViewControllers[safe: 0]?.view as? ImageReaderPageView)?.setImage(pages[self.readingMode == .rtl ? 0 : pages.count - 1])
                for _ in 0..<(pages.count - 1) {
                    pageViewControllers.insert(UIViewController(ImageReaderPageView(source: self.source)), at: 0)
                }
                pageViewControllers.insert(UIViewController(ImageReaderInfoPageView(
                    previous: self.readingMode == .rtl ? chapter : self.chapters[safe: self.chapter + 1],
                    next: self.readingMode == .rtl ? self.chapters[safe: self.chapter - 1] : chapter
                )), at: 0)
                if self.readingMode == .rtl ? hasNextChapter : hasPreviousChapter {
                    pageViewControllers.insert(UIViewController(ImageReaderPageView(source: self.source)), at: 0)
                }
                self.setViewControllers([self.pageViewControllers[pageViewControllers.count - 3]], direction: .reverse, animated: false)
                self.page = self.readingMode == .rtl ? 0 : details.pages.count - 1
                if self.readingMode == .rtl {
                    loadPages((self.page - 1)..<(self.page + self.pagesToPreload + 1))
                } else {
                    loadPages((self.page - self.pagesToPreload)..<(self.page + 1 + 1))
                }
            }
        }
        Task {
            if let entry = self.entry {
                await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                    .page(self.page + 1),
                    .chapter(self.chapters[self.chapter].chapter)
                ] + (self.chapters[self.chapter].volume.flatMap({ [ .volume($0) ] as [SoshikiAPI.HistoryQuery] }) ?? []))
                if let history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get() {
                    self.history = history
                    await TrackerManager.shared.setHistory(entry: entry, history: history)
                }
            }
        }
    }

    func move(toPage index: Int, animated: Bool = false) {
        guard let viewController = pageViewControllers[
            safe: self.readingMode == .rtl
                ? pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2)
                : index + (hasPreviousChapter ? 2 : 1)
        ] else { return }
        self.setViewControllers(
            [viewController],
            direction: (self.page < index) == (self.readingMode == .ltr) ? .forward : .reverse,
            animated: animated
        )
        self.page = index
    }
}

extension ImageReaderViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pageViewControllers.firstIndex(of: viewController), index > 0 {
//            loadPages((index - pagesToPreload - 1)..<(index))
            return pageViewControllers[index - 1]
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pageViewControllers.firstIndex(of: viewController), index < pageViewControllers.count - 1 {
//            loadPages((index + 1)..<(index + pagesToPreload + 1 + 1))
            return pageViewControllers[index + 1]
        } else {
            return nil
        }
    }
}

extension ImageReaderViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard let viewController = pageViewController.viewControllers?.first,
              let index = pageViewControllers.firstIndex(of: viewController) else { return }
        self.page = self.readingMode == .rtl
            ? pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2)
            : index -  (hasPreviousChapter ? 2 : 1)
        if index == (self.readingMode == .rtl ? pageViewControllers.count - 1 : 0) && hasPreviousChapter { // switch to previous chapter
            Task {
                await setChapter(to: self.chapter + 1, direction: .backward)
            }
        } else if index == (self.readingMode == .rtl ? 0 : pageViewControllers.count - 1) && hasNextChapter { // switch to next chapter
            Task {
                await setChapter(to: self.chapter - 1, direction: .forward)
            }
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let previousViewController = pageViewController.viewControllers?.first,
              let previousIndex = pageViewControllers.firstIndex(of: previousViewController),
              let nextViewController = pendingViewControllers.first,
              let nextIndex = pageViewControllers.firstIndex(of: nextViewController) else { return }
        if (previousIndex < nextIndex) == (self.readingMode == .ltr) { // forward movement
            loadPages((self.page)..<(self.page + self.pagesToPreload + 1 + 1))
        } else { // backward movement
            loadPages((self.page - self.pagesToPreload - 1)..<(self.page + 1))
        }
    }
}

extension ImageReaderViewController {
    @objc func leftPage() {
        guard page >= (hasPreviousChapter ? -1 : 0), page < (details?.pages.count ?? 0) + (hasNextChapter ? 1 : 0) else { return }
        if readingMode == .ltr {
            move(toPage: page - 1, animated: true)
            loadPages(
                (page - pagesToPreload)..<(page + 1 + 1)
            )
            if page == -2 { // switch to previous chapter
                Task {
                    await setChapter(to: chapter + 1, direction: .backward)
                }
            }
        } else {
            move(toPage: page + 1, animated: true)
            loadPages(
                (page - 1)..<(page + pagesToPreload + 1)
            )
            if page - 1 == details?.pages.count { // switch to next chapter
                Task {
                    await setChapter(to: chapter - 1, direction: .forward)
                }
            }
        }
    }

    @objc func rightPage() {
        guard page >= (hasPreviousChapter ? -1 : 0), page < (details?.pages.count ?? 0) + (hasNextChapter ? 1 : 0) else { return }
        if readingMode == .ltr {
            move(toPage: page + 1, animated: true)
            loadPages(
                (page - 1)..<(page + pagesToPreload + 1)
            )
            if page - 1 == details?.pages.count { // switch to next chapter
                Task {
                    await setChapter(to: chapter - 1, direction: .forward)
                }
            }
        } else {
            move(toPage: page - 1, animated: true)
            loadPages(
                (page - pagesToPreload)..<(page + 1 + 1)
            )
            if page == -2 { // switch to previous chapter
                Task {
                    await setChapter(to: chapter + 1, direction: .backward)
                }
            }
        }
    }

    @objc func previousChapter() {
        Task {
            await setChapter(to: chapter + 1, direction: .backward)
        }
    }

    @objc func nextChapter() {
        Task {
            await setChapter(to: chapter - 1, direction: .forward)
        }
    }

    @objc func openSettings() {
        present(ImageReaderSettingsViewController(), animated: true)
    }

    @objc func closeReader() {
        Task {
            if let entry = entry {
                await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                        .page(page + 1),
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

extension ImageReaderViewController {
    @objc func singleTap(_ gestureRecognizer: UITapGestureRecognizer? = nil) {
        if let gestureRecognizer {
            if CGRect(x: 0, y: 0, width: self.view.bounds.width / 4, height: self.view.bounds.height).contains(
                gestureRecognizer.location(in: self.view)
            ) {
                leftPage()
                return
            } else if CGRect(x: 0, y: self.view.bounds.width * 3 / 4, width: self.view.bounds.width / 4, height: self.view.bounds.height).contains(
                gestureRecognizer.location(in: self.view)
            ) {
                rightPage()
                return
            }
        }
        if self.navigationController?.navigationBar.isHidden == true {
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.toolbar.isHidden = false
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 1
                self.navigationController?.toolbar.alpha = 1
            }
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                self.navigationController?.navigationBar.alpha = 0
                self.navigationController?.toolbar.alpha = 0
            } completion: { _ in
                self.navigationController?.navigationBar.isHidden = true
                self.navigationController?.toolbar.isHidden = true
            }
        }
    }
}

enum ReadingMode: String, CaseIterable {
    case ltr = "Left to Right"
    case rtl = "Right to Left"
}

enum Direction {
    case forward
    case backward
    case none
}
