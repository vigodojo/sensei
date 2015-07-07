//
//  AffirmationsViewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/5/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData

class AffirmationsViewController: UserMessageViewController {

    private struct Constants {
        static let NumberOfAffirmations = 6
        static let EstimatedKeyboardHeight: CGFloat = 224
        static let MinTextViewHeight: CGFloat = 48
        static let KeyboardTextViewSpace: CGFloat = 4
    }
    
    @IBOutlet weak var textViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: PlaceholderedTextView!
    @IBOutlet weak var deleteButton: UIButton!
    
    private let DeleteConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to delete this Affirmation?")
    
    override weak var navigationView: NavigationView! {
        didSet {
            navigationView.titleLabel.text = "AFFIRMATIONS"
        }
    }
    
    override weak var messageSwitchView: MessageSwitchView! {
        didSet {
            messageSwitchView.delegate = self
        }
    }
    
    private lazy var affirmationsFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: Affirmation.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    private var keyboardHeight = Constants.EstimatedKeyboardHeight
    
    private var maxTextViewHeight: CGFloat {
        var height = CGRectGetHeight(UIScreen.mainScreen().bounds) - textViewBottomSpace - CGRectGetHeight(navigationView.frame) - CGRectGetHeight(messageSwitchView.frame)
        if let tutorialViewController = tutorialViewController where !tutorialViewController.tutorialHidden {
            height -= tutorialViewController.tutorialContainerHeight
        }
        return max(height, Constants.MinTextViewHeight)
    }
    
    private var textViewHeight: CGFloat {
       return min(max(textView.contentSize.height, Constants.MinTextViewHeight), maxTextViewHeight)
    }
    
    private var textViewBottomSpace: CGFloat {
        var space = CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight(navigationView.frame) - CGRectGetHeight(messageSwitchView.frame) - Constants.MinTextViewHeight
        if let tutorialViewController = tutorialViewController where !tutorialViewController.tutorialHidden {
            space -= tutorialViewController.tutorialContainerHeight
        }
        return min(keyboardHeight, space)
    }
    
    private var bottomContentOffset: CGFloat {
        var space = CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight(navigationView.frame) - CGRectGetHeight(messageSwitchView.frame) - keyboardHeight - textViewHeight
        if let tutorialViewController = tutorialViewController where !tutorialViewController.tutorialHidden {
            space -= tutorialViewController.tutorialContainerHeight
        }
        return abs(min(0, space))
    }
    
    private var hasDisplayedContent: Bool {
        return selectedAffirmation != nil || !textView.text.isEmpty
    }
    
    private var selectedAffirmation: Affirmation?
    
    // MARK: - UserMessageViewController
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            if !self.affirmationsFetchedResultController.performFetch(&error) {
                println("Failed to fetch user messages with error: \(error)")
            }

            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.messageSwitchView.reloadSlots()
                self.selectAffirmationWithNumber(NSNumber(integer:0))
            })
        })
    }
    
    override func hasChangesBeenMade() -> Bool {
        if let index = messageSwitchView.selectedSlot {
            let receiveTime = messageSwitchView.receiveTime
            if let affirmation = affirmationWithNumber(index) {
                return hasAffirmationBeenChanged(affirmation, newText: textView.text, newReceiveTime: receiveTime)
            }
            return !textView.text.isEmpty
        }
        return false
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        let height = size.height + Constants.KeyboardTextViewSpace
        if keyboardHeight != height {
            keyboardHeight = height
            let aTextViewBottomSpace = textViewBottomSpace
            let aTextViewHeight = textViewHeight
            let aBottomOffset = bottomContentOffset
            view.layoutIfNeeded()
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomContentOffset, right: 0)
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationOptions, animations: { [weak self] in
                self?.textViewBottomSpaceConstraint.constant = aTextViewBottomSpace
                self?.textViewHeightConstraint.constant = aTextViewHeight
                self?.scrollView.contentOffset = CGPoint(x: 0, y: aBottomOffset)
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    // MARK: - Tutorial
    
    override func handleTutorialMoving() {
        let aTextViewBottomSpace = textViewBottomSpace
        let aTextViewHeight = textViewHeight
        if textViewBottomSpaceConstraint.constant != aTextViewBottomSpace || textViewHeightConstraint.constant != aTextViewHeight {
            view.layoutIfNeeded()
            UIView.animateWithDuration(AnimationDuration, animations: { [weak self] in
                self?.textViewBottomSpaceConstraint.constant = aTextViewBottomSpace
                self?.textViewHeightConstraint.constant = aTextViewHeight
                self?.view.layoutIfNeeded()
            })
        }
    }
    
    override func handleYesAnswerNotification(notification: NSNotification) {
        textView.resignFirstResponder()
        deleteAffirmation()
    }
    
    // MARK: - Private
    
    private func updateTextViewHeight() {
        textView.layoutIfNeeded()
        let height = textViewHeight
        textViewHeightConstraint.constant = height
        textView.setContentOffset(CGPoint(x: 0, y: max(0, textView.contentSize.height - height)), animated: false)
    }
    
    private func hasAffirmationBeenChanged(affirmation: Affirmation, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return affirmation.text != newText || affirmation.receiveTime != newReceiveTime
    }
    
    private func selectAffirmationWithNumber(number: NSNumber) {
        messageSwitchView.selectedSlot = number.integerValue
        if let affirmation = affirmationWithNumber(number) {
            messageSwitchView.receiveTime = affirmation.receiveTime
            textView.text = affirmation.text
            updateTextViewHeight()
            deleteButton.hidden = false
            selectedAffirmation = affirmation
        } else {
            resetInfo()
        }
    }
    
    private func affirmationWithNumber(number: NSNumber) -> Affirmation? {
        if let fetchedObjects = affirmationsFetchedResultController.fetchedObjects as? [Affirmation] {
            let filteredMessages = fetchedObjects.filter(){ $0.number.compare(number) == .OrderedSame }
            return filteredMessages.first
        }
        return nil
    }
    
    private func saveAffirmation() {
        let text = textView.text
        let receiveTime = messageSwitchView.receiveTime
        if let affirmation = selectedAffirmation {
            if text.isEmpty {
                CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(affirmation)
            } else if affirmation.text != text || affirmation.receiveTime != receiveTime {
                affirmation.text = text
                affirmation.receiveTime = receiveTime
            }
        } else if !text.isEmpty {
            if let index = messageSwitchView.selectedSlot {
                Affirmation.createAffirmationNumber(index, text: text, receiveTime: receiveTime)
            }
        }
    }
    
    private func deleteAffirmation() {
        if let affirmation = selectedAffirmation {
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(affirmation)
        }
        resetInfo()
    }
    
    private func resetInfo() {
        messageSwitchView.receiveTime = .Morning
        textView.text = ""
        updateTextViewHeight()
        deleteButton.hidden = true
        selectedAffirmation = nil
    }
    
    // MARK: - IBActions
    
    @IBAction func delete() {
        if hasDisplayedContent {
            tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
        }
    }
}

// MARK: - MessageSwitchViewDelegate

extension AffirmationsViewController: MessageSwitchViewDelegate {
    
    func numberOfSlotsInMessageSwitchView(view: MessageSwitchView) -> Int {
        return Constants.NumberOfAffirmations
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectSlotAtIndex index: Int) {
        selectAffirmationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchView(view: MessageSwitchView, isSlotEmptyAtIndex index: Int) -> Bool {
        return affirmationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectReceiveTime receiveTime: ReceiveTime) { }
    
    func shouldActivateReceivingTimeViewInMessageSwitchView(view: MessageSwitchView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func didFinishPickingReceivingTimeInMessageSwitchView(view: MessageSwitchView) {
        if let affirmation = selectedAffirmation where affirmation.receiveTime != messageSwitchView.receiveTime {
            affirmation.receiveTime = messageSwitchView.receiveTime
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension AffirmationsViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let affirmation = anObject as? Affirmation {
            switch type {
                case .Insert:
                    messageSwitchView.reloadSlotAtIndex(affirmation.number.integerValue)
                    let number = ((affirmation.number.integerValue + 1) % Constants.NumberOfAffirmations)
                    selectAffirmationWithNumber(number)
                    APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
                case .Update:
                    let number = ((affirmation.number.integerValue + 1) % Constants.NumberOfAffirmations)
                    selectAffirmationWithNumber(number)
                    APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
                case .Delete:
                    messageSwitchView.reloadSlotAtIndex(affirmation.number.integerValue)
                    messageSwitchView.selectedSlot = affirmation.number.integerValue
                    APIManager.sharedInstance.deleteAffirmation(affirmation, handler: nil)
                default:
                    break
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension AffirmationsViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        saveAffirmation()
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView.contentSize.height != textViewHeightConstraint.constant {
            textViewHeightConstraint.constant = textViewHeight
        }
        deleteButton.hidden = !hasDisplayedContent
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
