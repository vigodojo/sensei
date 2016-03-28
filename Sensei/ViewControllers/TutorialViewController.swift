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
        static let NoAnswer = "TutorialBubbleCollectionViewCellNotificationsNoAnswer"
        static let YesAnswer = "TutorialBubbleCollectionViewCellNotificationsYesAnswer"
        static let AfirmationTap = "TutorialBubbleCollectionViewCellNotificationsAffirmatinTap"
        static let VisualizationTap = "TutorialBubbleCollectionViewCellNotificationsVisualizationTap"
    }
    
    private struct Constants {
        static let SpeechBubbleHeight: CGFloat = 82.0
    }
    
    enum MessageType {
        case Sensei
        case Me
        case Confirmation
    }

    @IBOutlet weak var tutorialContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tutorialContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tutorialCollectionView: UICollectionView!
    @IBOutlet weak var senseiImageView: AnimatableImageView!
    @IBOutlet weak var senseiTapView: UIView!
    @IBOutlet weak var senseiHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var warningTextView: UITextView!
    @IBOutlet weak var arrowMoreButton: UIButton!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!

    @IBOutlet weak var logTextView: UITextView!
    private var nextTimer: NSTimer?
    
    @IBAction func toggleLog(sender: AnyObject) {
        if let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as? String {
            UIPasteboard.generalPasteboard().string = idfa
            let alertController = UIAlertController(title: "Copied", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
//        logTextView.hidden = !logTextView.hidden
    }
    
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
    
    var type = MessageType.Sensei {
        didSet {
            switch type {
            case .Sensei:
                buttonsView.hidden = true
                arrowMoreButton.hidden = false
                setArrowButtonVisibleIfNeeded(nil)
            case .Confirmation:
                buttonsView.hidden = false
                arrowMoreButton.hidden = true
            default:
                break
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
        tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
        addTutorialObservers()
        configureBackground()
    }
    
    func configureBackground() {
        let screenHeight = CGRectGetHeight(UIScreen.mainScreen().bounds)
        let imageName = "top_background_\(Int(screenHeight))"
        backgroundImageView.image = UIImage(named: imageName)
//        senseiHeightConstraint.constant = screenHeight/4
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
    
    func showNextAffInstruction() {
        showInstruction(TutorialManager.sharedInstance.nextAffInstruction())
    }
    
    func showNextVisInstruction() {
        showInstruction(TutorialManager.sharedInstance.nextVisInstruction())
    }
    
    func showInstruction(instruction: String) {
        if !Settings.sharedSettings.tutorialOn.boolValue {
            return
        }
        let message = PlainMessage(attributedText: NSAttributedString(string: instruction, attributes: [NSFontAttributeName : UIFont.speechBubbleTextFont]))
        showMessage(message, upgrade: false)
    }
    
    func showWarningMessage(message: String, disappear: Bool) {
        if !warningTextView.hidden {
            return
        }
        warningTextView.alpha = 0.0
        warningTextView.hidden = false
        warningTextView.attributedText = NSAttributedString(string: message, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
        warningTextView.contentOffset = CGPointZero
        
        warningTextView.contentInset = UIEdgeInsetsZero
        warningTextView.textContainerInset = UIEdgeInsetsZero
        warningTextView.font = UIFont.speechBubbleTextFont
        warningTextView.layoutIfNeeded()
        arrowMoreButton.hidden = true
        
        UIView.animateWithDuration(0.3, animations: { [unowned self] () -> Void in
            self.warningTextView.alpha = 1.0
        }) { (finished) -> Void in
            if !disappear {
                return
            }
            UIView.animateWithDuration(0.3, delay: 2.0, options: .CurveEaseOut, animations:{ [unowned self] () -> Void in
                self.warningTextView.alpha = 0.0
            }) { (finished) -> Void in
                self.hideWarning()
            }
        }
    }

    func askConfirmationQuestion(question: ConfirmationQuestion) {
        showBlockingWindow()
        ask(question)
    }
    
    func ask(question: ConfirmationQuestion) {
        
        if tutorialHidden || TutorialManager.sharedInstance.completed {
            if TutorialManager.sharedInstance.completed {
                messages = [question]
                tutorialCollectionView.reloadData()
            } else {
                showWarningMessage(question.text, disappear: false)
            }
            showTutorialAnimated(true)
            setArrowButtonVisibleIfNeeded(self.tutorialCollectionView.scrollViewDidScrollToBottom())
        } else {
            showWarningMessage(question.text, disappear: false)
        }
        type = .Confirmation
    }
    
    func showVisualizationMessage(message: Message, visualization: Visualization?) {
        showMessage(message, upgrade: true) {() -> Void in
//            if let vis = visualization {
//                let cell = self.tutorialCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as! TutorialTextViewCell
//                cell.visualization = vis
//            }
        }
    }
    
    func showMessage(message: Message, upgrade: Bool) {
        showMessage(message, upgrade: upgrade, completion: nil)
    }
    
    func showMessage(message: Message, upgrade: Bool, completion: (()-> Void)?) {
        
        if !TutorialManager.sharedInstance.completed && (self.childViewControllers.first as! UINavigationController).viewControllers.count == 1 {
            if ((self.childViewControllers.first as! UINavigationController).viewControllers.first as! SenseiTabController).currentViewController is SenseiViewController  {
                return
            }
        }
        
        if messages.count == 0 || TutorialManager.sharedInstance.completed {
            messages = [message]
        } else {
            messages.append(message)
        }

        if tutorialHidden || TutorialManager.sharedInstance.completed {
            tutorialCollectionView.reloadData()
            showTutorialAnimated(true)
            setArrowButtonVisibleIfNeeded(self.tutorialCollectionView.scrollViewDidScrollToBottom())
            if let completion = completion {
                completion()
            }
        } else {
            let animated = TutorialManager.sharedInstance.prevTutorialStep?.requiresActionToProceed == true
            let lastIndexPath = NSIndexPath(forItem: self.messages.count-1, inSection: 0)
            tutorialCollectionView.performBatchUpdates({ [unowned self]() -> Void in
                self.tutorialCollectionView.insertItemsAtIndexPaths([lastIndexPath])
            
                }, completion: { [unowned self](finished) -> Void in
                    if animated {
                        self.tutorialCollectionView.scrollToItemAtIndexPath(lastIndexPath, atScrollPosition: .Top, animated: true)
                    }
                    self.setArrowButtonVisibleIfNeeded(self.tutorialCollectionView.scrollViewDidScrollToBottom())

                    if let completion = completion {
                        completion()
                    }
                })
        }
        if warningTextView.hidden {
            type = message is ConfirmationQuestion ? .Confirmation: .Sensei
        }
    }
    
    // MARK: - Tutorial
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        if self.nextTimer == nil || self.nextTimer?.valid == false {
            let visibleCells = tutorialCollectionView.indexPathsForVisibleItems()
            if visibleCells.count > 0 {
                if let cell = tutorialCollectionView.cellForItemAtIndexPath(visibleCells.first! as NSIndexPath) as? TutorialTextViewCell {
                    let visibleText = cell.textView.textInFrame(self.view.convertRect(tutorialCollectionView.frame, toView: cell.textView))
                    let delay = tutorialStep.delayBefore == 0 ? tutorialStep.delayBefore : ceil(Double((visibleText.characters.count)) * 0.03)
                    self.nextTimer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "didMoveToNextTutorialStepAction:", userInfo: tutorialStep, repeats: false)
                }
            } else {
                self.nextTimer = NSTimer.scheduledTimerWithTimeInterval(tutorialStep.delayBefore, target: self, selector: "didMoveToNextTutorialStepAction:", userInfo: tutorialStep, repeats: false)
            }
        }
    }
    
    func didMoveToNextTutorialStepAction(timer: NSTimer) {
        if let tutorialStep = timer.userInfo as? TutorialStep {
            if let animatableimage = tutorialStep.animatableImage {
                self.senseiImageView.stopAnimatableImageAnimation()
                
                if shouldShowAnimationAfterTutorialStep(tutorialStep) {
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
    
    func shouldShowAnimationAfterTutorialStep(tutorialStep: TutorialStep) -> Bool {
        return tutorialStep.number == 12 || tutorialStep.number == 18
    }
    
    func showTutorialStep(tutorialStep: TutorialStep) {
        if tutorialStep.screen != .Sensei {
            self.showMessage(tutorialStep, upgrade: false, completion: { () -> Void in
                self.nextTimer = nil
                self.autoShowNext()
            })
        }
    }
    
    func autoShowNext() {
        if self.senseiImageView.layerAnimating() {
            return
        }
        let show = tutorialCollectionView.frame.size.height >= tutorialCollectionView.contentSize.height - tutorialCollectionView.contentOffset.y
        
        if canLoadNextStep && self.nextTimer == nil && show && TutorialManager.sharedInstance.currentStep?.screen != .Sensei {
            TutorialManager.sharedInstance.nextStep()
        }
    }
    
    // MARK: - Private
    
    private func clear() {
        messages = []
        tutorialCollectionView.reloadData()
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
    
    private func setArrowButtonVisibleIfNeeded(hidden: Bool?) {
        if let hideNeeded = hidden {
            arrowMoreButton.hidden = hideNeeded
        } else {
            arrowMoreButton.hidden = tutorialCollectionView.frame.size.height >= tutorialCollectionView.contentSize.height - tutorialCollectionView.contentOffset.y
        }
    }
    
    private func performConfirmationSelectedAction() {
        hideWarning()
        if !BlockingWindow.shardeInstance.hidden {
            hideBlockingWindow()
        }
        type = .Sensei
        if TutorialManager.sharedInstance.completed {
            hideTutorialAnimated(true)
        }
    }
    
    private func hideWarning() {
        setArrowButtonVisibleIfNeeded(tutorialCollectionView.scrollViewDidScrollToBottom())
        self.warningTextView.alpha = 0.0
        self.buttonsView.hidden = true
        self.warningTextView.hidden = true
    }
    
    // MARK: - IBActions
    
    @IBAction func yesAction(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.YesAnswer, object: nil)
        performConfirmationSelectedAction()
    }
    
    @IBAction func noAction(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.NoAnswer, object: nil)
        performConfirmationSelectedAction()
    }
    
    @IBAction func touchOnSensei(senser: UITapGestureRecognizer) {
        if TutorialManager.sharedInstance.completed {
            hideTutorialAnimated(true)
            type = .Sensei
        } else if TutorialManager.sharedInstance.currentStep?.number >= 29 {
            if let animatableImage = AnimationManager.sharedManager.bowsAnimatableImage() {
                showWarningMessage("Not yet, we need to complete the tutorial first please.", disappear:  true)
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TutorialTextViewCell.ReuseIdentifier, forIndexPath: indexPath) as! TutorialTextViewCell
        let message = messages[indexPath.item]

        if let attributedText = message.attributedText {
            cell.textView.attributedText = attributedText
        } else {
            cell.textView.text = message.text
            cell.textView.font = UIFont.speechBubbleTextFont
        }
        cell.textView.contentInset = UIEdgeInsetsZero
        cell.textView.textContainerInset = UIEdgeInsetsZero
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TutorialViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let message = messages[indexPath.item]
        
        let textView = UITextView(frame: collectionView.bounds)
        textView.font = UIFont.speechBubbleTextFont
        textView.contentInset = UIEdgeInsetsZero
        textView.textContainerInset = UIEdgeInsetsZero
        if let attributedText = message.attributedText {
            textView.attributedText = attributedText
        } else {
            textView.text = message.text
        }
        textView.layoutIfNeeded()
        
        let height = ceil(textView.contentSize.height/collectionView.bounds.size.height) * collectionView.bounds.size.height
        return CGSize(width: CGRectGetWidth(collectionView.bounds), height: height)
    }
}

// MARK: - TutorialBubbleCollectionViewCellDelegate

extension TutorialViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView.scrollViewDidScrollToBottom() {
            autoShowNext()
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        setArrowButtonVisibleIfNeeded(scrollView.scrollViewDidScrollToBottom())
    }
}

extension TutorialViewController: UITextViewDelegate {
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        if URL == LinkToAppOnAppStore {
            UpgradeManager.sharedInstance.askForUpgrade()
            return false
        } else if URL == LinkToAffirmation {
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.AfirmationTap, object: nil)
            return false
        } else if URL == LinkToVisualization {
            var vis: Visualization? = nil
            if let cell = tutorialCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? SpeechBubbleCollectionViewCell {
                vis = cell.visualization
            }
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.VisualizationTap, object: vis)
            return false
        }
        
        return true;
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
