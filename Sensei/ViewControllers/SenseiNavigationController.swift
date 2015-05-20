//
//  SenseiNavigationController.swift
//  Sensei
//
//  Created by Sauron Black on 5/20/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiNavigationController: UIViewController {

    struct Item {
        var reuseIdentifier: String!
        var height: CGFloat!
    }
    
    var items = [Item]()
    
    @IBOutlet var collerctionView: UICollectionView!
}

extension SenseiNavigationController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = items[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SenseiNavigationController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let item = items[indexPath.item]
        return CGSize(width: CGRectGetWidth(collectionView.bounds), height: item.height)
    }
}
