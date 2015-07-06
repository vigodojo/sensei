//
//  SenseiNavigationController.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiNavigationController: BaseViewController {
    
    struct Constants {
        static let NavigationCellNibName = "NavigationCollectionViewCell"
        static let NavigationCellHeight: CGFloat = 31
    }

    class Item {
        var reuseIdentifier: String!
        var height: CGFloat!
        
        init(reuseIdentifier: String, height: CGFloat) {
            self.reuseIdentifier = reuseIdentifier
            self.height = height
        }
    }
    
    private var navigationItems = [Item(reuseIdentifier: Constants.NavigationCellNibName, height: Constants.NavigationCellHeight)]
    
    var contentItems = [Item]()
    
    var remainingHeight: CGFloat {
        let currentHeight = navigationItemsHeight + contentItems.reduce(0) { $0 + $1.height }
        return CGRectGetHeight(UIScreen.mainScreen().bounds) - currentHeight
    }
    
    var navigationItemsHeight: CGFloat {
        return navigationItems.reduce(0) {
            return $0 + $1.height
        }
    }
    
    private var navigationItemHidden = false
    
    weak var navigationCell: NavigationCollectionViewCell?
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.registerNib(UINib(nibName: Constants.NavigationCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.NavigationCellNibName)
        collectionView.bounces = false
    }
    
    func showNavigationItemAnimated(animated: Bool) {
        if navigationItemHidden {
            navigationItems.append(Item(reuseIdentifier: Constants.NavigationCellNibName, height: Constants.NavigationCellHeight))
            if !animated {
                collectionView.reloadData()
            } else {
                collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: navigationItems.count - 1, inSection: 0)])
            }
            navigationItemHidden = false
        }
    }
    
    func hideNavigationItemAnimated(animated: Bool) {
        if !navigationItemHidden {
            navigationItems.removeLast()
            if !animated {
                collectionView.reloadData()
            } else {
                collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: navigationItems.count, inSection: 0)])
            }
            navigationItemHidden = true
        }
    }
    
    private func itemForIndexPath(indexPath: NSIndexPath) -> Item {
        switch indexPath.section {
            case 0:
                return navigationItems[indexPath.item]
            default :
                return contentItems[indexPath.item]
        }
    }
}

// MARK: - UICollectionViewDataSource

extension SenseiNavigationController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case 0:
                return navigationItems.count
            default :
                return contentItems.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = itemForIndexPath(indexPath)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        if cell is NavigationCollectionViewCell {
            navigationCell = cell as? NavigationCollectionViewCell
            navigationCell?.delegate = self
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SenseiNavigationController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let item = itemForIndexPath(indexPath)
        return CGSize(width: CGRectGetWidth(collectionView.bounds), height: item.height)
    }
}

// MARK: - NavigationCollectionViewCellDelegate

extension SenseiNavigationController: NavigationCollectionViewCellDelegate {
    
    func navigationCollectionViewCellDidBack(cell: NavigationCollectionViewCell) {
        navigationController?.popViewControllerAnimated(true)
    }
}
