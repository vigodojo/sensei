//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class UserMessageViewController: BaseViewController, UINavigationControllerDelegate {
    
    var wasTutorialShown = false // temp
    
    private struct ControlNames {
        static let BackButton = "BackButton"
        static let SlotsCollectionView = "SlotsCollectionView"
        static let ReceiveTimeTextView = "ReceiveTimeTextView"
    }
    
    @IBOutlet weak var navigationView: NavigationView!
    @IBOutlet weak var messageSwitchView: MessageSwitchView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.delegate = self
        fetchUserMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObservers()
        addTutorialObservers()
        addTutorialViewObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        TutorialManager.sharedInstance.nextStep()
//        if !wasTutorialShown {
//            wasTutorialShown = true
//            tutorialViewController?.setTutorialHidden(!Settings.sharedSettings.tutorialOn.boolValue, animated: true)
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    deinit {
        println("\(self) ist Tod")
    }
    
    func fetchUserMessages() {
        
    }
    
    func hasChangesBeenMade() -> Bool {
        return false
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
    
    // MARK: - Private
    
    private func addSnapshot() {
        if let tutorialController = tutorialViewController where !tutorialController.tutorialHidden {
            let snapshotView = tutorialController.view.snapshotViewAfterScreenUpdates(false)
            view.clipsToBounds = false
            view.addSubview(snapshotView)
        }
    }
    
    private func addTutorialViewObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialWillShowNotification:"), name: TutorialViewController.Notifications.TutorialWillShow, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialWillHideNotification:"), name: TutorialViewController.Notifications.TutorialWillHide, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleYesAnswerNotification:"), name: SpeechBubbleCollectionViewCell.Notifications.YesAnswer, object: nil)
    }
}

// MARK: - NavigationViewDelegate

extension UserMessageViewController: NavigationViewDelegate {
    
    func navigationViewDidBack(cell: NavigationView) {
        addSnapshot()
        navigationController?.popViewControllerAnimated(true)
    }
}
