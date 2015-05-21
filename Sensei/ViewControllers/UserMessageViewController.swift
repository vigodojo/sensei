//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

enum UserMessageType: Printable {
    
    case Affirmation
    case Visualization
    
    var description: String {
        switch self {
            case .Affirmation: return "Affirmation"
            case .Visualization: return "Visualization"
        }
    }
}

class UserMessageViewController: SenseiNavigationController {
    
    private struct Constants {
        static let MessageSwitchCellReuseIdentifier = "MessageSwitchCollectionViewCell"
        static let MessageSwitchCellHeight: CGFloat = 170
        static let AffirmationCellReuseIdentifier = "AffirmationCollectionViewCell"
        static let AffirmationCellHeight: CGFloat = 110
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "\(userMessageType)"
        }
    }
    
    var userMessageType = UserMessageType.Affirmation
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupItems()
        addKeyboardObservers()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - SenseiNavigationController
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is MessageSwitchCollectionViewCell {
            (cell as! MessageSwitchCollectionViewCell).delegate = self
        }
        return cell
    }
    
    // MARK: - Private
    
    private func setupItems() {
        items.append(Item(reuseIdentifier: Constants.MessageSwitchCellReuseIdentifier, height: Constants.MessageSwitchCellHeight))
        switch userMessageType {
            case UserMessageType.Affirmation:
                items.append(Item(reuseIdentifier: Constants.AffirmationCellReuseIdentifier, height: Constants.AffirmationCellHeight))
            case UserMessageType.Visualization:
                // TODO: - Add Visualization Cell
                break
        }
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
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

// MARK: - MessageSwitchCollectionViewCellDelegate

extension UserMessageViewController: MessageSwitchCollectionViewCellDelegate {
    
    func messageSwitchCollectionViewCellDidSave(cell: MessageSwitchCollectionViewCell) {
        println("\(self) Save")
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectMessageAtIndex index: Int) {
        println("\(self) MessageAtIndex \(index)")
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime) {
        println("\(self) ReceiveTime \(receiveTime)")
    }
}
