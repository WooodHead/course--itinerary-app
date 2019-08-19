//
//  TripActivitiesViewController.swift
//  Itinerary
//
//  Created by Brian Sipple on 8/16/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import UIKit

class TripActivitiesViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    
    
    var viewModel: TripActivitiesViewModel!
    var modelController: TripActivitiesModelController!
    
    
    private var currentDataSnapshot: DataSourceSnapshot!
    private var dataSource: DataSource!
}


// MARK: - Layout Structure
private extension TripActivitiesViewController {
//    enum TableSection {
//        case day
//    }
    
    enum SupplementaryViewKind {
        static let sectionHeader = "Section Header"
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<TripDay, TripActivity>
    typealias SectionSupplementaryViewProvider = DataSource.SupplementaryViewProvider
    typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<TripDay, TripActivity>
}


// MARK: - Layout Composition
private extension TripActivitiesViewController {
    
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(56))
        
        let dayItem = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [dayItem])
        let section = NSCollectionLayoutSection(group: group)
        
        section.contentInsets = .init(top: 0, leading: 16, bottom: 36, trailing: 16)
        section.interGroupSpacing = 14
        
        let layoutSectionHeader = makeLayoutSectionHeader()

        section.boundarySupplementaryItems = [layoutSectionHeader]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
    func makeLayoutSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(18))
        
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: SupplementaryViewKind.sectionHeader,
            alignment: .top,
            absoluteOffset: CGPoint(x: 0, y: -8)
        )
    }
    
    
    func makeSectionSupplementaryViewProvider() -> SectionSupplementaryViewProvider {
        return {
            [weak self] (
                collectionView: UICollectionView,
                kind: String,
                indexPath: IndexPath
            ) -> UICollectionReusableView? in
                
            guard kind == SupplementaryViewKind.sectionHeader else {
                preconditionFailure("Unknown kind for supplementary view")
            }
            
            guard
                let tripActivity = self?.dataSource.itemIdentifier(for: indexPath),
                let tripDay = self?.currentDataSnapshot.sectionIdentifier(containingItem: tripActivity)
            else {
                preconditionFailure("Unable to find section identifier for trip day")
            }
            
            let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: R.reuseIdentifier.tripDayCollectionSectionHeader.identifier,
                for: indexPath
            )
            
            
            self?.configure(sectionHeaderView, for: tripDay)
            
            return sectionHeaderView
        }
    }
    
    
    func configure(_ sectionHeaderView: UICollectionReusableView, for tripDay: TripDay) {
        guard let headerView = sectionHeaderView as? TripDayCollectionHeaderReusableView else {
            preconditionFailure("Unknown header view type")
        }
        
        headerView.viewModel = .init(
            date: tripDay.date,
            subtitle: tripDay.subtitle
        )
    }
    
    
    func configure(_ activityCell: UICollectionViewCell, for tripActivity: TripActivity) {
        guard let cell = activityCell as? TripActivityCollectionViewCell else {
            preconditionFailure("Unknown cell type")
        }
        
        cell.viewModel = .init(
            activityTitle: tripActivity.title,
            activitySubtitle: tripActivity.subtitle,
            activityType: tripActivity.activityType
        )
    }
}


// MARK: - Lifecycle
extension TripActivitiesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "No viewModel was set")
        assert(modelController != nil, "No modelController was set")
        
        dataSource = makeDataSource()
        setupLayout()
        
        updateSnapshot(withNew: modelController.days)
    }
}


// MARK: - Private Helpers
private extension TripActivitiesViewController {
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: {
                [weak self] (collectionView, indexPath, tripActivity) -> UICollectionViewCell in
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: R.reuseIdentifier.tripActivityCell.identifier,
                    for: indexPath
                )
                
                self?.configure(cell, for: tripActivity)
                
                return cell
            }
        )
        
        dataSource.supplementaryViewProvider = makeSectionSupplementaryViewProvider()
        
        return dataSource
    }
    
    
    func setupLayout() {
        collectionView.register(
            TripActivityCollectionViewCell.nib,
            forCellWithReuseIdentifier: R.reuseIdentifier.tripActivityCell.identifier
        )
        
        collectionView.register(
            TripDayCollectionHeaderReusableView.nib,
            forSupplementaryViewOfKind: SupplementaryViewKind.sectionHeader,
            withReuseIdentifier: R.reuseIdentifier.tripDayCollectionSectionHeader.identifier
        )
        
        
        collectionView.collectionViewLayout = createLayout()
//        collectionView.delegate = self
    }
    
    
    func updateSnapshot(withNew days: [TripDay], animate: Bool = true) {
        guard let dataSource = dataSource else { return }
        
        currentDataSnapshot = dataSource.snapshot()
        currentDataSnapshot.appendSections(days)
        
        for day in days {
            currentDataSnapshot.appendItems(day.activities, toSection: day)
        }
        
        dataSource.apply(currentDataSnapshot, animatingDifferences: animate)
    }
}


extension TripActivitiesViewController: Storyboarded {}