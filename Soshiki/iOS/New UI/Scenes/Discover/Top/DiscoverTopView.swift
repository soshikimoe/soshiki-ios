//
//  DiscoverTopView.swift
//  Soshiki
//
//  Created by Jim Phieffer on 3/7/23.
//

import UIKit

class DiscoverTopView: UICollectionViewCell {
    var entries: [SourceEntry]!

    let collectionView: UICollectionView
    let headerView: ExpandableSectionHeaderView
    let backgroundGradientLayer: CAGradientLayer

    var dataSource: UICollectionViewDiffableDataSource<Int, SourceEntry>!

    weak var delegate: (any DiscoverViewControllerChildDelegate)?

    override var bounds: CGRect {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            self.backgroundGradientLayer.frame = self.bounds
            CATransaction.commit()
        }
    }

    override init(frame: CGRect) {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(350),
                heightDimension: .absolute(150)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let section = NSCollectionLayoutSection(
            group: NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .absolute(350),
                    heightDimension: .absolute(450)
                ),
                subitem: item,
                count: 3
            )
        )
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)

        let layout = DiscoverTopCollectionViewCompositionalLayout(
            section: section,
            configuration: configuration
        )
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        self.headerView = ExpandableSectionHeaderView()
        self.backgroundGradientLayer = CAGradientLayer()

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
        reloadData()
    }

    func configureSubviews() {
        self.headerView.setTitle(to: "Top Rated")
        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.headerView)

        self.collectionView.delegate = self
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.backgroundColor = .clear
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.collectionView)

        self.backgroundGradientLayer.colors = [ UIColor.clear.cgColor, UIColor.systemGray6.cgColor ]
        self.backgroundGradientLayer.locations = [ 0, 1 ]
        self.backgroundGradientLayer.frame = self.bounds
        self.backgroundGradientLayer.needsDisplayOnBoundsChange = true

        self.contentView.layer.insertSublayer(backgroundGradientLayer, at: 0)
    }

    func applyConstraints() {
        NSLayoutConstraint.activate([
            self.headerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            self.headerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            self.headerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),

            self.collectionView.topAnchor.constraint(equalTo: self.headerView.bottomAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    func configureDataSource() -> UICollectionViewDiffableDataSource<Int, SourceEntry> {
        let cellRegistration = UICollectionView.CellRegistration<DiscoverTopEntryView, SourceEntry> { [weak self] cell, _, entry in
            cell.setEntry(to: entry, number: (self?.entries.firstIndex(of: entry) ?? -1) + 1)
        }

        return UICollectionViewDiffableDataSource<Int, SourceEntry>(collectionView: collectionView) { collectionView, indexPath, entry in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: entry)
        }
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SourceEntry>()
        snapshot.append(entries)
        self.dataSource.apply(snapshot, to: 0)
    }
}

// MARK: - DiscoverTopView + UICollectionViewDelegate

extension DiscoverTopView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let entry = self.entries[safe: indexPath.item] {
            self.delegate?.didSelect(entry: entry)
        }
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}
