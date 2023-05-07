//
//  DiscoverFeaturedView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/7/23.
//

import UIKit

class DiscoverFeaturedView: UICollectionReusableView {
    var entries: [SourceEntry]!

    let collectionView: UICollectionView
    let pageControl: UIPageControl

    var dataSource: UICollectionViewDiffableDataSource<Int, SourceEntry>!

    weak var delegate: (any DiscoverViewControllerChildDelegate)?

    override init(frame: CGRect) {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        configuration.contentInsetsReference = .none

        let layout = UICollectionViewCompositionalLayout(
            section: NSCollectionLayoutSection(
                group: NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    ),
                    subitems: [
                        NSCollectionLayoutItem(
                            layoutSize: NSCollectionLayoutSize(
                                widthDimension: .fractionalWidth(1),
                                heightDimension: .fractionalHeight(1)
                            )
                        )
                    ]
                )
            ),
            configuration: configuration
        )
        self.collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        self.pageControl = UIPageControl()

        super.init(frame: frame)

        self.dataSource = configureDataSource()

        configureSubviews()
        applyConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEntries(to entries: [SourceEntry]) {
        self.entries = entries
        self.pageControl.numberOfPages = self.entries.count
        reloadData()
    }

    func configureSubviews() {
        self.collectionView.delegate = self
        self.collectionView.isPagingEnabled = true
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.collectionView.bounces = false

        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.collectionView)

        self.pageControl.tintColor = .white
        self.pageControl.translatesAutoresizingMaskIntoConstraints = false
        self.pageControl.addTarget(self, action: #selector(pageControlValueChanged(_:)), for: .touchUpInside)
        self.addSubview(self.pageControl)

        self.backgroundColor = .black
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.collectionView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -32),

            self.pageControl.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.pageControl.topAnchor.constraint(equalTo: self.collectionView.bottomAnchor, constant: 8),
            self.pageControl.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
    }

    func configureDataSource() -> UICollectionViewDiffableDataSource<Int, SourceEntry> {
        let cellRegistration = UICollectionView.CellRegistration<DiscoverFeaturedEntryView, SourceEntry> { cell, _, entry in
            cell.setEntry(to: entry)
            cell.delegate = self.delegate
        }

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, entry in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entry)
        }
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SourceEntry>()
        snapshot.append(entries)
        self.dataSource.apply(snapshot, to: 0)
    }

    @objc func pageControlValueChanged(_ sender: UIPageControl) {
        self.collectionView.scrollToItem(at: IndexPath(item: sender.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - DiscoverFeaturedView + UICollectionViewDelegate

extension DiscoverFeaturedView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells {
            if let entryView = cell as? DiscoverFeaturedEntryView {
                entryView.scrollViewDidScroll(scrollView)
            }
        }

        if scrollView.isPagingEnabled { // the pagination scrollview
            self.pageControl.currentPage = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        }
    }
}
