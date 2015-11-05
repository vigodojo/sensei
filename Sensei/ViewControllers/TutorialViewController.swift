//
//  TutorialViewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/30/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class TutorialViewController: BaseViewController {
    
    struct Notifications {
        static let TutorialWillShow = "TutorialViewControllerNotificationsTutorialWillShow"
        static let TutorialDidShow = "TutorialViewControllerNotificationsTutorialDidShow"
        static let TutorialWillHide = "TutorialViewControllerNotificationsTutorialWillHide"
        static let TutorialDidHide = "TutorialViewControllerNotificationsTutorialDidHide"
    }
    
    private struct Constants {
        static let SpeechBubbleHeight: CGFloat = 82.0
    }

    @IBOutlet weak var tutorialContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tutorialContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var senseiImageView: AnimatableImageView!
    
    var tutorialContainerHeight: CGFloat {
        return tutorialContainerViewHeightConstraint.constant
    }
    
    private var _tutorialHidden = false
    var tutorialHidden: Bool {
        get {
            return _tutorialHidden
        }
        set {
            if newValue {
                hideTutorialAnimated(false)
            } else {
                showTutorialAnimated(false)
            }
        }
    }
    
    var messages = [Message]()
    
    var canLoadNextStep: Bool {
        if !TutorialManager.sharedInstance.completed {
            if let tutorialStep = TutorialManager.sharedInstance.currentStep {
                return !tutorialStep.requiresActionToProceed
            }
        }
        return false
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: TutorialBubbleCollectionViewCell.ReuseIdentifier, bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: TutorialBubbleCollectionViewCell.ReuseIdentifier)
        tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
        addTutorialObservers()
    }
    
    // MARK: - Public 
    
    func setTutorialHidden(hidden: Bool, animated: Bool) {
        if hidden {
            hideTutorialAnimated(animated)
        } else {
            showTutorialAnimated(animated)
        }
    }
    
    func showTutorialAnimated(animated: Bool) {
        if _tutorialHidden {
            _tutorialHidden = false
            if !animated {
                tutorialContainerViewTopConstraint.constant = 0
                view.layoutIfNeeded()
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialDidShow, object: nil)
            } else {
                view.layoutIfNeeded()
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialWillShow, object: nil)
                UIView.animateWithDuration(AnimationDuration, animations: { [unowned self] () -> Void in
                    self.tutorialContainerViewTopConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { finished in
                        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialDidShow, object: nil)
                })
            }
        }
    }
    
    func hideTutorialAnimated(animated: Bool) {
        if !_tutorialHidden {
            _tutorialHidden = true
            if !animated {
                tutorialContainerViewTopConstraint.constant = -tutorialContainerHeight
                view.layoutIfNeeded()
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialDidHide, object: nil)
                clear()
            } else {
                view.layoutIfNeeded()
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialWillHide, object: nil)
                UIView.animateWithDuration(AnimationDuration, animations: { [unowned self] () -> Void in
                    self.tutorialContainerViewTopConstraint.constant = -self.tutorialContainerHeight
                    self.view.layoutIfNeeded()
                }, completion: { [unowned self] finished in
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.TutorialDidHide, object: nil)
                    self.clear()
                })
            }
            if !BlockingWindow.shardeInstance.hidden {
                hideBlockingWindow()
            }
        }
    }
    
    func askConfirmationQuestion(question: ConfirmationQuestion) {
        showBlockingWindow()
        showMessage(question)
    }
    
    func showMessage(message: Message) {
        let isInsert = (messages.count == 0)
        messages = [message]
        if tutorialHidden {
            collectionView.reloadData()
            showTutorialAnimated(true)
        } else {
            if isInsert {
                collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
            } else {
                collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
            }
        }
    }
    
    // MARK: - Tutorial
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        if tutorialStep.screen != .Sensei {
            showMessage(tutorialStep)
        }
        if let animatableimage = tutorialStep.animatableImage {
            senseiImageView.stopAnimatableImageAnimation()
            senseiImageView.animateAnimatableImage(animatableimage, completion: nil)
        }
    }
    
    // MARK: - Private
    
    private func clear() {
        messages = []
        collectionView.reloadData()
    }
    
    private func showBlockingWindow() {
        let edgeInsets = UIEdgeInsets(top: tutorialContainerHeight, left: 0.0, bottom: 0.0, right: 0.0)
        let blockingWindowEndFrame = UIEdgeInsetsInsetRect(UIScreen.mainScreen().bounds, edgeInsets)
        if tutorialHidden {
            BlockingWindow.showWithStartFrame(UIScreen.mainScreen().bounds, endFrame: blockingWindowEndFrame)
        } else {
            BlockingWindow.showWithStartFrame(blockingWindowEndFrame, endFrame: blockingWindowEndFrame)
        }
    }
    
    private func hideBlockingWindow() {
        let edgeInsets = UIEdgeInsets(top: tutorialContainerHeight, left: 0.0, bottom: 0.0, right: 0.0)
        let blockingWindowStartFrame = UIEdgeInsetsInsetRect(UIScreen.mainScreen().bounds, edgeInsets)
        BlockingWindow.hideWithStartFrame(blockingWindowStartFrame, endFrame: UIScreen.mainScreen().bounds)
    }
    
    // MARK: - IBActions
    
    @IBAction func touchOnSensei(senser: UITapGestureRecognizer) {
        if TutorialManager.sharedInstance.completed {
            hideTutorialAnimated(true)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension TutorialViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TutorialBubbleCollectionViewCell.ReuseIdentifier, forIndexPath: indexPath) as! TutorialBubbleCollectionViewCell
        let message = messages[indexPath.item]
        if let attributedText = message.attributedText {
            cell.setAttributedString(attributedText)
        } else {
            cell.text = message.text
        }
        cell.delegate = self
        cell.type = message is ConfirmationQuestion ? .Confirmation: .Sensei
        return cell;
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TutorialViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: CGRectGetWidth(collectionView.bounds), height: Constants.SpeechBubbleHeight)
    }
}

// MARK: - TutorialBubbleCollectionViewCellDelegate

extension TutorialViewController: TutorialBubbleCollectionViewCellDelegate {
    
    func tutorialBubbleCollectionViewCellDidYes(cell: TutorialBubbleCollectionViewCell) {
        hideTutorialAnimated(true)
    }
    
    func tutorialBubbleCollectionViewCellDidNo(cell: TutorialBubbleCollectionViewCell) {
        hideTutorialAnimated(true)
    }
    
    func tutorialBubbleCollectionViewCellDidNext(cell: TutorialBubbleCollectionViewCell) {
        if canLoadNextStep {
            TutorialManager.sharedInstance.nextStep()
        }
    }
    
    func tutorialBubbleCollectionViewCellCanShowMoreMessages(cell: TutorialBubbleCollectionViewCell) -> Bool {
        return canLoadNextStep
    }
}

// MARK: - UIViewController+TutorialViewController

extension UIViewController {
    
    var tutorialViewController: TutorialViewController? {
        var viewController = parentViewController
        while viewController != nil && !(viewController is TutorialViewController) {
            viewController = viewController?.parentViewController
        }
        return viewController as? TutorialViewController
    }

}
