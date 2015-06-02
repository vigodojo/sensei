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
        static let TutorialCellNibName = "TutorialCollectionViewCell"
        static let TutorialCellHeight: CGFloat = 100
        static let NavigationCellNibName = "NavigationCollectionViewCell"
        static let NavigationCellHeight: CGFloat = 31
    }

    struct Item {
        var reuseIdentifier: String!
        var height: CGFloat!
    }
    
    var items = [Item]()
    
    var remainingHeight: CGFloat {
        let currentHeight = items.reduce(0) { $0 + $1.height }
        return CGRectGetHeight(UIScreen.mainScreen().bounds) - currentHeight
    }
    
    var tutorialOn: Bool {
        return true
    }
    
    weak var tutorialCell: TutorialCollectionViewCell?
    weak var navigationCell: NavigationCollectionViewCell?
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.registerNib(UINib(nibName: Constants.TutorialCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.TutorialCellNibName)
        collectionView.registerNib(UINib(nibName: Constants.NavigationCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.NavigationCellNibName)
        
        if tutorialOn {
            items.append(Item(reuseIdentifier: Constants.TutorialCellNibName, height: Constants.TutorialCellHeight))
        }
        items.append(Item(reuseIdentifier: Constants.NavigationCellNibName, height: Constants.NavigationCellHeight))
    }
}

extension SenseiNavigationController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = items[indexPath.item]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
        if cell is TutorialCollectionViewCell {
            tutorialCell = cell as? TutorialCollectionViewCell
        } else if cell is NavigationCollectionViewCell {
            navigationCell = cell as? NavigationCollectionViewCell
            navigationCell?.delegate = self
        }
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

extension SenseiNavigationController: NavigationCollectionViewCellDelegate {
    
    func navigationCollectionViewCellDidBack(cell: NavigationCollectionViewCell) {
        navigationController?.popViewControllerAnimated(true)
    }
}
