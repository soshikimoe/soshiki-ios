//
//  ReaderView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 11/20/22.
//

import UIKit
import SwiftUI
import NukeUI

enum ReadingMode: String, CaseIterable {
    case ltr = "Left to Right"
    case rtl = "Right to Left"
}

struct ImageReaderView: View {
    @StateObject var imageReaderViewModel: ImageReaderViewModel

    @State var settingsViewShown = false

    @MainActor init(chapters: [ImageSourceChapter], chapter: Int, source: ImageSource, entry: Entry?, history: History?) {
        self._imageReaderViewModel = StateObject(
            wrappedValue: ImageReaderViewModel(chapters: chapters, chapter: chapter, source: source, entry: entry, history: history)
        )
    }

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationStack {
            ImageReaderRepresentableView(viewModel: imageReaderViewModel, viewController: imageReaderViewModel.viewController)
                .edgesIgnoringSafeArea(.all)
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        if let entry = imageReaderViewModel.entry {
                            await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                                    .page(imageReaderViewModel.page + 1),
                                    .chapter(imageReaderViewModel.chapters[imageReaderViewModel.chapter].chapter)
                            ] + (imageReaderViewModel.chapters[imageReaderViewModel.chapter].volume.flatMap({
                                    [ .volume($0) ] as [SoshikiAPI.HistoryQuery]
                                }) ?? [])
                            )
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await imageReaderViewModel.viewController.setChapter(
                            to: imageReaderViewModel.chapter + (imageReaderViewModel.readingMode == .rtl ? -1 : 1),
                            direction: imageReaderViewModel.readingMode == .rtl ? .forward : .backward
                        )
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    if let volume = imageReaderViewModel.chapters[imageReaderViewModel.chapter].volume, !volume.isNaN {
                        Text("Volume \(volume.toTruncatedString())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("Chapter \(imageReaderViewModel.chapters[imageReaderViewModel.chapter].chapter.toTruncatedString())")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await imageReaderViewModel.viewController.setChapter(
                            to: imageReaderViewModel.chapter + (imageReaderViewModel.readingMode == .rtl ? 1 : -1),
                            direction: imageReaderViewModel.readingMode == .rtl ? .backward : .forward
                        )
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settingsViewShown.toggle()
                } label: {
                    Image(systemName: "gear")
                }.sheet(isPresented: $settingsViewShown) {
                    NavigationView {
                        ImageReaderSettingsView(imageReaderViewModel: imageReaderViewModel).toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button {
                                    settingsViewShown = false
                                } label: {
                                    Text("Done").bold()
                                }
                            }
                        }.navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
        }.toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    imageReaderViewModel.handleTap(onToolbar: true)
                    imageReaderViewModel.leftTap()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .status) {
                let clampedPage = (imageReaderViewModel.page + 1).clamped(to: 0..<(imageReaderViewModel.details?.pages.count ?? 0))
                Text("Page \(clampedPage) of \(imageReaderViewModel.details?.pages.count ?? 0)")
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    imageReaderViewModel.handleTap(onToolbar: true)
                    imageReaderViewModel.rightTap()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(imageReaderViewModel.toolbarShown ? .visible : .hidden, for: .navigationBar)
        .toolbar(imageReaderViewModel.toolbarShown ? .visible : .hidden, for: .bottomBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onTapGesture(count: 2, coordinateSpace: .global) { location in
            (imageReaderViewModel.viewController.viewControllers?[safe: 0]?.view as? UIImageReaderPageView)?
                .zoomableView.zoom(to: location, animated: true)
        }
        .onTapGesture(count: 1, coordinateSpace: .global) { location in
            if location.x < UIScreen.main.bounds.width / 6 {
                imageReaderViewModel.leftTap()
            } else if UIScreen.main.bounds.width - location.x < UIScreen.main.bounds.width / 6 {
                imageReaderViewModel.rightTap()
            } else {
                imageReaderViewModel.handleTap()
            }
        }.onAppear {
            imageReaderViewModel.toolbarHideTask = Task {
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)

                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        imageReaderViewModel.toolbarShown = false
                    }
                }
            }
        }.onChange(of: imageReaderViewModel.readingMode) { _ in
            Task {
                await imageReaderViewModel.viewController.setChapter(to: imageReaderViewModel.chapter, direction: .none)
            }
        }
    }
}

@MainActor class ImageReaderViewModel: ObservableObject {
    var chapters: [ImageSourceChapter]
    @Published var chapter: Int = 0
    var source: ImageSource

    @Published var details: ImageSourceChapterDetails?

    @Published var toolbarHideTask: Task<Void, Error>?
    @Published var toolbarShown: Bool = true

    @Published var page: Int = 0

    @AppStorage("settings.image.pagesToPreload") var pagesToPreload = 3
    @AppStorage("settings.image.readingMode") var readingMode: ReadingMode = .rtl

    var entry: Entry?
    var history: History?

    var viewController = ImageReaderViewController()

    init(chapters: [ImageSourceChapter],
         chapter: Int,
         source: ImageSource,
         entry: Entry?,
         history: History?
    ) {
        self.chapters = chapters
        self.source = source
        self.chapter = chapter
        self.entry = entry
        self.history = history

        if let page = history?.page {
            self.page = page - 1
        }
    }

    func handleTap(onToolbar: Bool = false) {
        if let toolbarHideTask = toolbarHideTask {
            toolbarHideTask.cancel()
        }
        if toolbarShown, !onToolbar {
            withAnimation(.easeInOut(duration: 0.25)) {
                toolbarShown = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                toolbarShown = true
            }
            toolbarHideTask = Task {
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)

                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        toolbarShown = false
                    }
                }
            }
        }
    }

    @MainActor func leftTap() {
        if readingMode == .ltr, page > (viewController.hasPreviousChapter ? 0 : -1) {
            viewController.move(toPage: page - 1, animated: true)
            viewController.loadPages(
                (page - pagesToPreload)..<(page + 1 + 1)
            )
            if page == -1 { // switch to previous chapter
                Task {
                    await viewController.setChapter(to: chapter + 1, direction: .backward)
                }
            }
        } else if page < (details?.pages.count ?? 0) + (viewController.hasNextChapter ? 1 : 0) {
            viewController.move(toPage: page + 1, animated: true)
            viewController.loadPages(
                (page - 1)..<(page + pagesToPreload + 1)
            )
            if page - 1 == details?.pages.count { // switch to next chapter
                Task {
                    await viewController.setChapter(to: chapter - 1, direction: .forward)
                }
            }
        }
    }

    @MainActor func rightTap() {
        if readingMode == .ltr, page < (details?.pages.count ?? 0) + (viewController.hasNextChapter ? 1 : 0) {
            viewController.move(toPage: page + 1, animated: true)
            viewController.loadPages(
                (page - 1)..<(page + pagesToPreload + 1)
            )
            if page - 1 == details?.pages.count { // switch to next chapter
                Task {
                    await viewController.setChapter(to: chapter - 1, direction: .forward)
                }
            }
        } else if page > (viewController.hasPreviousChapter ? 0 : -1) {
            viewController.move(toPage: page - 1, animated: true)
            viewController.loadPages(
                (page - pagesToPreload)..<(page + 1 + 1)
            )
            if page == -1 { // switch to previous chapter
                Task {
                    await viewController.setChapter(to: chapter + 1, direction: .backward)
                }
            }
        }
    }
}

struct ImageReaderRepresentableView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ImageReaderViewModel

    var viewController: ImageReaderViewController

    @MainActor init(viewModel: ImageReaderViewModel, viewController: ImageReaderViewController) {
        self.viewController = viewController
        self.viewModel = viewModel
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        viewController.coordinator = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor class Coordinator {
        var parent: ImageReaderRepresentableView

        init (_ parent: ImageReaderRepresentableView) {
            self.parent = parent
        }

        var chapter: Int {
            get { parent.viewModel.chapter }
            set { parent.viewModel.chapter = newValue }
        }

        var page: Int {
            get { parent.viewModel.page }
            set { parent.viewModel.page = newValue }
        }

        var readingMode: ReadingMode {
            parent.viewModel.readingMode
        }

        var pagesToPreload: Int {
            parent.viewModel.pagesToPreload
        }

        var chapters: [ImageSourceChapter] {
            parent.viewModel.chapters
        }

        var entry: Entry? {
            parent.viewModel.entry
        }

        var history: History? {
            get { parent.viewModel.history }
            set { parent.viewModel.history = newValue }
        }
    }
}

class ImageReaderViewController: UIPageViewController {
    var pages: [String] = []

    var pageViewControllers: [UIViewController] = []

    var coordinator: ImageReaderRepresentableView.Coordinator!

    var previousDetails: ImageSourceChapterDetails?
    var nextDetails: ImageSourceChapterDetails?

    var hasPreviousChapter: Bool { coordinator.chapter < coordinator.chapters.count - 1 }
    var hasNextChapter: Bool { coordinator.chapter > 0 }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        self.dataSource = self
        self.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await self.setChapter(to: coordinator.chapter, direction: .none)
        }
    }

    func loadPages(_ range: Range<Int>) {
        for index in range {
            guard let pageView = pageViewControllers[
                safe: coordinator.readingMode == .rtl
                    ? (pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2))
                    : (index + (hasPreviousChapter ? 2 : 1))
            ]?.view as? UIImageReaderPageView,
                  pageView.imageView.image == nil,
                  let page = pages[safe: index] else { continue }
            pageView.setImage(page)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func setChapter(to chapterIndex: Int, direction: Direction) async {
        if let chapter = coordinator.chapters[safe: chapterIndex] {
            let details: ImageSourceChapterDetails!
            if let previousDetails, previousDetails.id == chapter.id {
                nextDetails = coordinator.parent.viewModel.details
                details = previousDetails
                Task { [weak self] in
                    guard let self, let previousChapter = coordinator.chapters[safe: chapterIndex + 1] else { return }
                    self.previousDetails = await self.coordinator.parent.viewModel.source.getChapterDetails(
                        id: previousChapter.id, entryId: previousChapter.entryId
                    )
                    if let preloadedPageView = pageViewControllers[
                        safe: coordinator.readingMode == .rtl ? pageViewControllers.count - 1 : 0
                    ]?.view as? UIImageReaderPageView,
                       let lastPage = self.previousDetails?.pages.last?.url {
                        preloadedPageView.setImage(lastPage)
                    }
                }
            } else if let nextDetails, nextDetails.id == chapter.id {
                previousDetails = coordinator.parent.viewModel.details
                details = nextDetails
                Task { [weak self] in
                    guard let self, let nextChapter = coordinator.chapters[safe: chapterIndex - 1] else { return }
                    self.nextDetails = await self.coordinator.parent.viewModel.source.getChapterDetails(
                        id: nextChapter.id, entryId: nextChapter.entryId
                    )
                    if let preloadedPageView = pageViewControllers[
                        safe: coordinator.readingMode == .rtl ? 0 : pageViewControllers.count - 1
                    ]?.view as? UIImageReaderPageView,
                       let firstPage = self.nextDetails?.pages.first?.url {
                        preloadedPageView.setImage(firstPage)
                    }
                }
            } else {
                guard let fetchedDetails = await coordinator.parent.viewModel.source.getChapterDetails(
                    id: chapter.id,
                    entryId: chapter.entryId
                ) else { return }
                details = fetchedDetails
                Task { [weak self] in
                    guard let self else { return }
                    if let previousChapter = coordinator.chapters[safe: chapterIndex + 1] {
                        self.previousDetails = await self.coordinator.parent.viewModel.source.getChapterDetails(
                            id: previousChapter.id, entryId: previousChapter.entryId
                        )
                        if let preloadedPageView = pageViewControllers[
                            safe: coordinator.readingMode == .rtl ? pageViewControllers.count - 1 : 0
                        ]?.view as? UIImageReaderPageView,
                           let lastPage = self.previousDetails?.pages.last?.url {
                            preloadedPageView.setImage(lastPage)
                        }
                    }
                    if let nextChapter = coordinator.chapters[safe: chapterIndex - 1] {
                        self.nextDetails = await self.coordinator.parent.viewModel.source.getChapterDetails(
                            id: nextChapter.id, entryId: nextChapter.entryId
                        )
                        if let preloadedPageView = pageViewControllers[
                            safe: coordinator.readingMode == .rtl ? 0 : pageViewControllers.count - 1
                        ]?.view as? UIImageReaderPageView,
                           let firstPage = self.nextDetails?.pages.first?.url {
                            preloadedPageView.setImage(firstPage)
                        }
                    }
                }
            }

            self.pages = details.pages.compactMap({ $0.url })
            coordinator.chapter = chapterIndex
            coordinator.parent.viewModel.details = details

            if direction == .none {
                pageViewControllers = []
                if coordinator.readingMode == .rtl ? hasNextChapter : hasPreviousChapter {
                    pageViewControllers.append(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)))
                }
                pageViewControllers.append(UIViewController(UIImageReaderInfoPageView(
                    previous: coordinator.readingMode == .rtl ? chapter : coordinator.chapters[safe: coordinator.chapter + 1],
                    next: coordinator.readingMode == .rtl ? coordinator.chapters[safe: coordinator.chapter + 1] : chapter
                )))
                for _ in 0..<pages.count {
                    pageViewControllers.append(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)))
                }
                pageViewControllers.append(UIViewController(UIImageReaderInfoPageView(
                    previous: coordinator.readingMode == .rtl ? coordinator.chapters[safe: coordinator.chapter + 1] : chapter,
                    next: coordinator.readingMode == .rtl ? chapter : coordinator.chapters[safe: coordinator.chapter - 1]
                )))
                if coordinator.readingMode == .rtl ? hasPreviousChapter : hasNextChapter {
                    pageViewControllers.append(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)))
                }
                self.setViewControllers([pageViewControllers[
                    coordinator.readingMode == .rtl
                        ? pageViewControllers.count - coordinator.page - (hasPreviousChapter ? 3 : 2)
                        : coordinator.page + (hasPreviousChapter ? 2 : 1)
                ]], direction: .forward, animated: false)
                loadPages((coordinator.page - coordinator.pagesToPreload)..<(coordinator.page + coordinator.pagesToPreload + 1))
            } else if (direction == .forward) == (coordinator.readingMode == .ltr) { // if forward in ltr, or backward in rtl
                for viewController in pageViewControllers.dropLast(3) {
                    viewController.view.removeFromSuperview()
                    viewController.removeFromParent()
                }
                pageViewControllers.removeFirst(pageViewControllers.count - 3)
                (pageViewControllers[safe: 2]?.view as? UIImageReaderPageView)?.setImage(pages[coordinator.readingMode == .rtl ? pages.count - 1 : 0])
                for _ in 0..<(pages.count - 1) {
                    pageViewControllers.append(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)))
                }
                pageViewControllers.append(UIViewController(UIImageReaderInfoPageView(
                    previous: coordinator.readingMode == .rtl ? coordinator.chapters[safe: coordinator.chapter + 1] : chapter,
                    next: coordinator.readingMode == .rtl ? chapter : coordinator.chapters[safe: coordinator.chapter - 1]
                )))
                if coordinator.readingMode == .rtl ? hasPreviousChapter : hasNextChapter {
                    pageViewControllers.append(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)))
                }
                self.setViewControllers([pageViewControllers[2]], direction: .forward, animated: false)
                coordinator.page = coordinator.readingMode == .rtl ? details.pages.count - 1 : 0
                if coordinator.readingMode == .rtl {
                    loadPages((coordinator.page - coordinator.pagesToPreload)..<(coordinator.page + 1 + 1))
                } else {
                    loadPages((coordinator.page - 1)..<(coordinator.page + coordinator.pagesToPreload + 1))
                }
            } else if (direction == .backward) == (coordinator.readingMode == .ltr) { // if backward in ltr, or forward in rtl
                for viewController in pageViewControllers.dropFirst(3) {
                    viewController.view.removeFromSuperview()
                    viewController.removeFromParent()
                }
                pageViewControllers.removeLast(pageViewControllers.count - 3)
                (pageViewControllers[safe: 0]?.view as? UIImageReaderPageView)?.setImage(pages[coordinator.readingMode == .rtl ? 0 : pages.count - 1])
                for _ in 0..<(pages.count - 1) {
                    pageViewControllers.insert(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)), at: 0)
                }
                pageViewControllers.insert(UIViewController(UIImageReaderInfoPageView(
                    previous: coordinator.readingMode == .rtl ? chapter : coordinator.chapters[safe: coordinator.chapter + 1],
                    next: coordinator.readingMode == .rtl ? coordinator.chapters[safe: coordinator.chapter - 1] : chapter
                )), at: 0)
                if coordinator.readingMode == .rtl ? hasNextChapter : hasPreviousChapter {
                    pageViewControllers.insert(UIViewController(UIImageReaderPageView(source: coordinator.parent.viewModel.source)), at: 0)
                }
                self.setViewControllers([self.pageViewControllers[pageViewControllers.count - 3]], direction: .reverse, animated: false)
                coordinator.page = coordinator.readingMode == .rtl ? 0 : details.pages.count - 1
                if coordinator.readingMode == .rtl {
                    loadPages((coordinator.page - 1)..<(coordinator.page + coordinator.pagesToPreload + 1))
                } else {
                    loadPages((coordinator.page - coordinator.pagesToPreload)..<(coordinator.page + 1 + 1))
                }
            }
        }
        Task {
            if let entry = coordinator.entry {
                await SoshikiAPI.shared.setHistory(mediaType: entry.mediaType, id: entry._id, query: [
                    .page(coordinator.page + 1),
                    .chapter(coordinator.chapters[coordinator.chapter].chapter)
                ] + (coordinator.chapters[coordinator.chapter].volume.flatMap({ [ .volume($0) ] as [SoshikiAPI.HistoryQuery] }) ?? []))
                coordinator.history = try? await SoshikiAPI.shared.getHistory(mediaType: entry.mediaType, id: entry._id).get()
            }
        }
    }

    func move(toPage index: Int, animated: Bool = false) {
        guard let viewController = pageViewControllers[
            safe: coordinator.readingMode == .rtl
                ? pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2)
                : index + (hasPreviousChapter ? 2 : 1)
        ] else { return }
        self.setViewControllers(
            [viewController],
            direction: (coordinator.page < index) == (coordinator.readingMode == .ltr) ? .forward : .reverse,
            animated: animated
        )
        coordinator.page = index
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
        coordinator.page = coordinator.readingMode == .rtl
            ? pageViewControllers.count - index - (hasPreviousChapter ? 3 : 2)
            : index -  (hasPreviousChapter ? 2 : 1)
        if index == (coordinator.readingMode == .rtl ? pageViewControllers.count - 1 : 0) && hasPreviousChapter { // switch to previous chapter
            Task {
                await setChapter(to: coordinator.chapter + 1, direction: .backward)
            }
        } else if index == (coordinator.readingMode == .rtl ? 0 : pageViewControllers.count - 1) && hasNextChapter { // switch to next chapter
            Task {
                await setChapter(to: coordinator.chapter - 1, direction: .forward)
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
        if (previousIndex < nextIndex) == (coordinator.readingMode == .ltr) { // forward movement
            loadPages((coordinator.page)..<(coordinator.page + coordinator.pagesToPreload + 1 + 1))
        } else { // backward movement
            loadPages((coordinator.page - coordinator.pagesToPreload - 1)..<(coordinator.page + 1))
        }
    }
}

enum Direction {
    case forward
    case backward
    case none
}
