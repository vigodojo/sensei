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
    
    private var nextTimer: NSTimer?
    
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
        ask(question)
    }
    
    func ask(question: ConfirmationQuestion) {
        
        if tutorialHidden || TutorialManager.sharedInstance.completed {
            messages = [question]

            collectionView.reloadData()
            showTutorialAnimated(true)
        } else {
            let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as! TutorialBubbleCollectionViewCell
            
            cell.showWarningMessage(question.text, disappear: false)
            cell.type = .Confirmation
        }
    }
    
    func showMessage(message: Message, upgrade: Bool) {
        messages = [message]

        if tutorialHidden || TutorialManager.sharedInstance.completed {
            collectionView.reloadData()
            showTutorialAnimated(true)
        } else {
            let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as! TutorialBubbleCollectionViewCell
            
            cell.append(message.text, autoscroll: (TutorialManager.sharedInstance.prevTutorialStep?.requiresActionToProceed)!)
            cell.type = message is ConfirmationQuestion ? .Confirmation: .Sensei
        }
    }
    
    // MARK: - Tutorial
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        if self.nextTimer == nil || self.nextTimer?.valid == false {
            self.nextTimer = NSTimer.scheduledTimerWithTimeInterval(tutorialStep.delayBefore, target: self, selector: "didMoveToNextTutorialStepAction:", userInfo: tutorialStep, repeats: false)
        }
    }
    
    func didMoveToNextTutorialStepAction(timer: NSTimer) {
        if let tutorialStep = timer.userInfo as? TutorialStep {
            if let animatableimage = tutorialStep.animatableImage {
                self.senseiImageView.stopAnimatableImageAnimation()
                if tutorialStep.number == 12 || tutorialStep.number == 18 {
                    self.showMessage(tutorialStep, upgrade: false)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(2) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.senseiImageView.animateAnimatableImage(animatableimage, completion: { [unowned self] (finished) -> Void in
                            self.nextTimer = nil
                            self.autoShowNext()
                        })
                    }
                } else {
                    self.senseiImageView.animateAnimatableImage(animatableimage, completion: { [unowned self] (finished) -> Void in
                        self.showTutorialStep(tutorialStep)
                    })
                }
            } else {
                self.showTutorialStep(tutorialStep)
            }
        }
    }
    
    func showTutorialStep(tutorialStep: TutorialStep) {
        if tutorialStep.screen != .Sensei {
            self.showMessage(tutorialStep, upgrade: false)
            self.nextTimer = nil
            self.autoShowNext()
        }
    }
    
    func autoShowNext() {
        if self.senseiImageView.layerAnimating() {
            return
        }
        var show = true;
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? TutorialBubbleCollectionViewCell {
            let textView = UITextView(frame: cell.textView.bounds)
            textView.font = cell.textView.font
            textView.text = cell.textView.text.componentsSeparatedByString("\n\n").last?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            textView.layoutIfNeeded()
            
            show = textView.contentSize.height <= CGRectGetMaxY(cell.textView.bounds) || cell.textView.frame.size.height >= cell.textView.contentSize.height - cell.textView.contentOffset.y
        }
        
        if canLoadNextStep && self.nextTimer == nil && show && TutorialManager.sharedInstance.currentStep?.screen != .Sensei {
            TutorialManager.sharedInstance.nextStep()
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
        } else if TutorialManager.sharedInstance.currentStep?.number >= 29 {
            if let animatableImage = AnimationManager.sharedManager.bowsAnimatableImage() {
                let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as! TutorialBubbleCollectionViewCell
                cell.showWarningMessage("Not yet, we need to complete the tutorial first please.", disappear:  true)
                senseiImageView.animateAnimatableImage(animatableImage, completion: nil)
            }
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
        cell.type = message is ConfirmationQuestion ? .Confirmation: .Sensei
        
        if let attributedText = message.attributedText {
            cell.setAttributedString(attributedText)
        } else {
            cell.text = message.text
        }
        cell.delegate = self
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
    
    func performConfirmationSelectedAction(cell: TutorialBubbleCollectionViewCell) {
        cell.hideWarning()
        if !BlockingWindow.shardeInstance.hidden {
            hideBlockingWindow()
        }
        cell.type = .Sensei
        if TutorialManager.sharedInstance.completed {
            hideTutorialAnimated(true)
        }
    }
    
    func tutorialBubbleCollectionViewCellDidYes(cell: TutorialBubbleCollectionViewCell) {
        performConfirmationSelectedAction(cell)
    }
    
    func tutorialBubbleCollectionViewCellDidNo(cell: TutorialBubbleCollectionViewCell) {
        performConfirmationSelectedAction(cell)
    }
    
    func tutorialBubbleCollectionViewCellDidNext(cell: TutorialBubbleCollectionViewCell) {
        autoShowNext()
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
