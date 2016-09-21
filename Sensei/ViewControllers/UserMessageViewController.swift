//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class UserMessageViewController: BaseViewController, UINavigationControllerDelegate {
    
    private struct ControlNames {
        static let BackButton = "BackButton"
        static let SlotsCollectionView = "SlotsCollectionView"
        static let ReceiveTimeTextView = "ReceiveTimeTextView"
    }
    
    @IBOutlet weak var navigationView: NavigationView!
    @IBOutlet weak var messageSwitchView: MessageSwitchView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var didNextStep = false // TODO: Fix this some where, some how.
    
    var upgradeAppMessage: String {
        return ""
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.delegate = self
        fetchUserMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObservers()
        addTutorialViewObservers()
        addTutorialObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !didNextStep {
            TutorialManager.sharedInstance.nextStep()
            didNextStep = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
        removeTutorialViewObservers()
        removeTutorialObservers()
    }
    
    deinit {
        print("\(self) ist Tod")
    }
    
    // MARK: - Public
    
    func fetchUserMessages() {
        
    }
    
    func hasChangesBeenMade() -> Bool {
        return false
    }
    
    func showUpgradeAppMessage() {
        let messageText = NSMutableAttributedString(string: upgradeAppMessage, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
        let range = (upgradeAppMessage as NSString).rangeOfString("upgrade")
        messageText.addAttribute(NSLinkAttributeName, value: LinkToAppOnAppStore, range: range)
        tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: true)
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [weak self] in
            self?.scrollView.contentInset = UIEdgeInsetsZero
        }, completion: nil)
    }
    
    // MARK: - Tutorial
    
    override func enableControls(controlNames: [String]?) {
        navigationView.backButton.userInteractionEnabled = controlNames?.contains(ControlNames.BackButton) ?? true
        messageSwitchView.slotsCollectionView.userInteractionEnabled = controlNames?.contains(ControlNames.SlotsCollectionView) ?? true
        messageSwitchView.receiveTimeButton.userInteractionEnabled = controlNames?.contains(ControlNames.ReceiveTimeTextView) ?? true
    }
    
    // MARK: - Tutorial View
    
    func tutorialWillShowNotification(notification: NSNotification) {
        handleTutorialMoving()
    }
    
    func tutorialWillHideNotification(notification: NSNotification) {
        handleTutorialMoving()
    }
    
    func handleTutorialMoving() {}
    
    func handleYesAnswerNotification(notification: NSNotification) {}
    
    func handleNoAnswerNotification(notification: NSNotification) {}
    
    // MARK: - Private
    
    private func addSnapshot() {
        if let tutorialController = tutorialViewController where !tutorialController.tutorialHidden {
            let snapshotView = tutorialController.view.snapshotViewAfterScreenUpdates(false)
            view.clipsToBounds = false
            view.addSubview(snapshotView!)
        }
    }
    
    private func addTutorialViewObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserMessageViewController.tutorialWillShowNotification(_:)), name: TutorialViewController.Notifications.TutorialWillShow, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserMessageViewController.tutorialWillHideNotification(_:)), name: TutorialViewController.Notifications.TutorialWillHide, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserMessageViewController.handleYesAnswerNotification(_:)), name: TutorialBubbleCollectionViewCell.Notifications.YesAnswer, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserMessageViewController.handleNoAnswerNotification(_:)), name: TutorialBubbleCollectionViewCell.Notifications.NoAnswer, object: nil)
    }
    
    private func removeTutorialViewObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialViewController.Notifications.TutorialWillShow, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialViewController.Notifications.TutorialWillHide, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialBubbleCollectionViewCell.Notifications.YesAnswer, object: nil)
    }
}

// MARK: - NavigationViewDelegate

extension UserMessageViewController: NavigationViewDelegate {
    
    func navigationViewDidBack(cell: NavigationView) {
        addSnapshot()
        backDidPress()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func backDidPress() {
        
    }
}
