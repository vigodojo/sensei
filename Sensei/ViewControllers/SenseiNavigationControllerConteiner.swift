//
//  SenseiNavigationControllerConteiner.swift
//  Sensei
//
//  Created by Sauron Black on 6/18/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiNavigationControllerConteiner: SenseiNavigationController {
    
    private struct Constants {
        static let ContainerCellNibName = "ContainerCollectionViewCell"
        static let SegueIdentifier = "EmbededTabBar"
    }
    
    var embededController: UIViewController? {
        didSet {
            if let viewController = embededController {
                addChildViewController(viewController)
                if let containerView = containerCell {
                    viewController.view.removeFromSuperview()
                    containerView.contentView.addEdgePinnedSubview(viewController.view)
                }
            }
        }
    }

    weak var containerCell: ContainerCollectionViewCell? {
        didSet {
            if let viewController = embededController, containerView = containerCell {
                viewController.view.removeFromSuperview()
                containerView.contentView.addEdgePinnedSubview(viewController.view)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        hideTutorialAnimated(false)
        hideNavigationItemAnimated(false)
        performSegueWithIdentifier(Constants.SegueIdentifier, sender: self)
        setupItems()
    }
    
    // MARK: - Public
    
    func setupItems() {
        collectionView.registerNib(UINib(nibName: Constants.ContainerCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.ContainerCellNibName)
        contentItems.append(Item(reuseIdentifier: Constants.ContainerCellNibName, height: remainingHeight))
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is ContainerCollectionViewCell {
            containerCell = (cell as? ContainerCollectionViewCell)
        }
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 1 {
            return CGSize(width: CGRectGetWidth(collectionView.frame), height: CGRectGetHeight(collectionView.frame) - navigationItemsHeight)
        } else {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: indexPath)
        }
    }
    
    // MARK: Private
}
