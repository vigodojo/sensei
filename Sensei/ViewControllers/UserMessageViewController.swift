//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class UserMessageViewController: SenseiNavigationController, UINavigationControllerDelegate {
    
    struct Constants {
        static let MessageSwitchCellNibName = "MessageSwitchCollectionViewCell"
        static let MessageSwitchCellHeight: CGFloat = 81
    }
    
    var messageSwitchCell: MessageSwitchCollectionViewCell?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupItems()
        fetchUserMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - SenseiNavigationController
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is MessageSwitchCollectionViewCell {
            messageSwitchCell = (cell as? MessageSwitchCollectionViewCell)
        }
        return cell
    }
    
    // MARK: - Public
    
    func setupItems() {
        collectionView.registerNib(UINib(nibName: Constants.MessageSwitchCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.MessageSwitchCellNibName)
        items.append(Item(reuseIdentifier: Constants.MessageSwitchCellNibName, height: Constants.MessageSwitchCellHeight))
    }
    
    func fetchUserMessages() {
        
    }
    
    func hasChangesBeenMade() -> Bool {
        return false
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if let textView = messageSwitchCell?.receiveTimeTextView where textView.isFirstResponder() {
            return;
        }
        let offset = size.height - (CGRectGetHeight(collectionView.frame) - collectionView.contentSize.height)
        if  offset > 0 {
            collectionView.bounces = true
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
            UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
                self.collectionView.contentOffset = CGPoint(x: 0, y: offset)
            }, completion: nil)
        }
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        collectionView.bounces = false
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
            self.collectionView.contentInset = UIEdgeInsetsZero
        }, completion: nil)
    }
}
