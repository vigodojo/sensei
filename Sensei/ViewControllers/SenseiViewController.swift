//
//  SenseiViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiViewController: UIViewController {
    
    private struct Constants {
        static let CellReuseIdentifier = "SpeechBubbleCollectionViewCell"
    }

    @IBOutlet weak var collectionView: UICollectionView!
}

extension SenseiViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! SpeechBubbleCollectionViewCell
        return cell;
    }
}

extension SenseiViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = CGRectGetWidth(UIEdgeInsetsInsetRect(collectionView.bounds, flowLayout.sectionInset))
        return CGSize(width: width, height: 150.0)
    }
}