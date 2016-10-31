//
//  AffirmationsViewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/5/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData

class AffirmationsViewController: UserMessageViewController, NSFetchedResultsControllerDelegate {

    private struct Constants {
        static let NumberOfAffirmations = 6
        static let NumberOfFreeAffirmations = 2
        static let EstimatedKeyboardHeight: CGFloat = 224
        static let MinTextViewHeight: CGFloat = 59//48
        static let KeyboardTextViewSpace: CGFloat = 11//4
    }
    
    private struct ControlNames {
        static let TextView = "TextView"
        static let LongPress = "LongPress"
    }
    
    @IBOutlet weak var textViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: PlaceholderedTextView!
    
    private let DeleteConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to delete this Affirmation?")

    private func ReceiveTimeConfirmationQuestion(receiveTime: ReceiveTime) -> PlainMessage {
        return PlainMessage(text: "There can be only one affirmation set for \(receiveTime.description.lowercaseString).")
    }
    
    override weak var navigationView: NavigationView! {
        didSet {
            navigationView.titleLabel.text = "AFFIRMATIONS"
        }
    }
    
    override weak var messageSwitchView: MessageSwitchView! {
        didSet {
            messageSwitchView.delegate = self
            messageSwitchView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    override var upgradeAppMessage: String {
        return "You can only use slots 1 and 2 in the free version of this app, please upgrade to unlock all the slots."
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
    
    private var itemToDelete: Int?;
    
    private var swipeNextGesture: UISwipeGestureRecognizer?
    private var swipePrevGesture: UISwipeGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        swipeNextGesture = UISwipeGestureRecognizer(target: self, action: #selector(AffirmationsViewController.showNextSlot(_:)))
        swipeNextGesture!.direction = .Left
        self.view.addGestureRecognizer(swipeNextGesture!)

        swipePrevGesture = UISwipeGestureRecognizer(target: self, action: #selector(AffirmationsViewController.showPrevSlot(_:)))
        swipePrevGesture!.direction = .Right
        self.view.addGestureRecognizer(swipePrevGesture!)
    }
    
    func showNextSlot(notification: NSNotification) {
        let indexPath = NSIndexPath(forItem: messageSwitchView.selectedSlot! + 1, inSection: 0)
        if !UpgradeManager.sharedInstance.isProVersion() && indexPath.item >= Constants.NumberOfFreeAffirmations {
            if TutorialManager.sharedInstance.completed {
                showUpgradeAppMessage()
            }
            return
        }
        if indexPath.item >= Constants.NumberOfAffirmations {
            return
        }
        messageSwitchView.slotsCollectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
        messageSwitchView.collectionView(messageSwitchView.slotsCollectionView, didSelectItemAtIndexPath: indexPath)
    }

    func showPrevSlot(notification: NSNotification) {
        let indexPath = NSIndexPath(forItem: messageSwitchView.selectedSlot!-1, inSection: 0)
        if indexPath.item < 0 {
            return
        }
        messageSwitchView.slotsCollectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
        messageSwitchView.collectionView(messageSwitchView.slotsCollectionView, didSelectItemAtIndexPath: indexPath)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AffirmationsViewController.didUpgradeToPro(_:)), name: UpgradeManager.Notifications.DidUpgrade, object: nil)
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            
            strongSelf.swipeNextGesture?.enabled = true
            strongSelf.swipePrevGesture?.enabled = true
            
            strongSelf.scrollView.contentInset = UIEdgeInsetsZero
            strongSelf.saveAffirmation()
            strongSelf.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if TutorialManager.sharedInstance.completed {
            tutorialViewController!.showNextAffInstruction()
        }
    }
    
    func didUpgradeToPro(notification: NSNotification) {
        navigationController?.popViewControllerAnimated(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        CoreDataManager.sharedInstance.saveContext()
        
        APIManager.sharedInstance.lessonsHistoryCompletion(nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func backDidPress() {
        SoundController.playSwish()
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        super.keyboardWillHideWithSize(size, animationDuration: animationDuration, animationOptions: animationOptions)
        swipeNextGesture?.enabled = true
        swipePrevGesture?.enabled = true
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: {
            self.scrollView.contentInset = UIEdgeInsetsZero
        }, completion: nil)
    }
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        swipeNextGesture?.enabled = false
        swipePrevGesture?.enabled = false
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: {
            self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, size.height, 0)
        }, completion: nil)
    }
    
    // MARK: - UserMessageViewController
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            do {
                try self.affirmationsFetchedResultController.performFetch()
            } catch let error1 as NSError {
                error = error1
                print("Failed to fetch user messages with error: \(error)")
            } catch {
                fatalError()
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
    
    
    // MARK: - Tutorial
    
    override func enableControls(controlNames: [String]?) {
        super.enableControls(controlNames)
        var delay: Float = 0
        if let names = controlNames where names.contains(ControlNames.TextView) {
            delay = 4
        }
        dispatchInMainThreadAfter(delay: delay) {
            self.textView.userInteractionEnabled = controlNames?.contains(ControlNames.TextView) ?? true
            self.messageSwitchView.longPressGesture.enabled = controlNames?.contains(ControlNames.TextView) ?? true
            self.swipeNextGesture?.enabled = self.messageSwitchView.slotsCollectionView.userInteractionEnabled
            self.swipePrevGesture?.enabled = self.messageSwitchView.slotsCollectionView.userInteractionEnabled
        }
    }
    
    override func handleYesAnswerNotification(notification: NSNotification) {
        if itemToDelete != nil {
            textView.resignFirstResponder()
            deleteAffirmation()
        }
    }

    // MARK: - Private
    
    private func hasAffirmationBeenChanged(affirmation: Affirmation, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return affirmation.text != newText || affirmation.receiveTime != newReceiveTime
    }
    
    private func fillAffirmationWithNumber(number: NSNumber) {
        if let affirmation = affirmationWithNumber(number) {
            messageSwitchView.receiveTime = affirmation.receiveTime
            textView.text = affirmation.text

            selectedAffirmation = affirmation
        } else {
            resetInfo()
        }
    }
    
    private func selectAffirmationWithNumber(number: NSNumber) {
        messageSwitchView.selectedSlot = number.integerValue
        fillAffirmationWithNumber(number)
    }
    
    private func affirmationWithNumber(number: NSNumber) -> Affirmation? {
        if let fetchedObjects = affirmationsFetchedResultController.fetchedObjects as? [Affirmation] {
            let filteredMessages = fetchedObjects.filter(){ $0.number.compare(number) == .OrderedSame }
            return filteredMessages.first
        }
        return nil
    }
    
    private func affirmationsWithReceiveTime(receiveTime: ReceiveTime) -> [Affirmation]? {
        if let fetchedObjects = affirmationsFetchedResultController.fetchedObjects as? [Affirmation] {
            let filteredMessages = fetchedObjects.filter(){ $0.receiveTime == receiveTime }
            return filteredMessages
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
                if !APIManager.sharedInstance.reachability.isReachable() {
                    affirmation.updatedOffline = NSNumber(bool: true)
                    tutorialViewController?.showNoInternetConnection()
                }
                CoreDataManager.sharedInstance.saveContext()
            }
        } else if !text.isEmpty {
            if let index = messageSwitchView.selectedSlot {
                let affirmation = Affirmation.createAffirmationNumber(index, text: text, receiveTime: receiveTime)
                if !APIManager.sharedInstance.reachability.isReachable() {
                    affirmation.updatedOffline = NSNumber(bool: true)
                    tutorialViewController?.showNoInternetConnection()
                }
                CoreDataManager.sharedInstance.saveContext()
                TutorialManager.sharedInstance.nextStep()
            }
        } else {
            CoreDataManager.sharedInstance.saveContext()
        }
    }
    
    private func deleteAffirmation() {
        if let aff = Affirmation.affirmationWithNumber(itemToDelete!) {
            if !APIManager.sharedInstance.reachability.isReachable() {
                OfflineManager.sharedManager.affirmationDeleted(aff.number)
                tutorialViewController?.showNoInternetConnection()
            }
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(aff)
            CoreDataManager.sharedInstance.saveContext()
            itemToDelete = nil
            if aff == selectedAffirmation {
                resetInfo()
            }
        } else if let affirmation = selectedAffirmation {
            if !APIManager.sharedInstance.reachability.isReachable() {
                OfflineManager.sharedManager.affirmationDeleted(affirmation.number)
                tutorialViewController?.showNoInternetConnection()
            }
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(affirmation)
            CoreDataManager.sharedInstance.saveContext()
            resetInfo()
        }
    }
    
    private func resetInfo() {
        messageSwitchView.receiveTime = .AnyTime
        textView.text = ""
        textView.contentOffset = CGPointZero;
        selectedAffirmation = nil
    }
    
    // MARK: - IBActions
    
    @IBAction func delete() {
        if hasDisplayedContent {
            tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
        }
    }
    
    func deleteItem(atIndex index: Int) {
        if let aff = Affirmation.affirmationWithNumber(index) {
            if aff.text.characters.count > 0 {
                itemToDelete = index
                tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
            }
        }
    }
    

	// MARK: - NSFetchedResultsControllerDelegate

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		if let affirmation = anObject as? Affirmation {
			switch type {
			case .Insert:
				selectedAffirmation = affirmation
				if TutorialManager.sharedInstance.completed {
					APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
				}
				messageSwitchView.reloadSlotAtIndex(affirmation.number.integerValue)
			case .Update:
				if TutorialManager.sharedInstance.completed {
					APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
				}
			case .Delete:
				messageSwitchView.reloadSlotAtIndex(affirmation.number.integerValue)
                APIManager.sharedInstance.deleteAffirmationWithNumber(affirmation.number, handler: nil)
			default:
				break
			}
		}
	}
}

// MARK: - MessageSwitchViewDelegate

extension AffirmationsViewController: MessageSwitchViewDelegate {

    func numberOfSlotsInMessageSwitchView(view: MessageSwitchView) -> Int {
        return Constants.NumberOfAffirmations
    }

    func messageSwitchView(view: MessageSwitchView, didSelectSlotAtIndex index: Int) {
        textView.placeholder = String(format: "Slot %i is empty. \nPlease tap here to create a new affirmation", index+1)
        fillAffirmationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchView(view: MessageSwitchView, isSlotEmptyAtIndex index: Int) -> Bool {
        return affirmationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectReceiveTime receiveTime: ReceiveTime) { }
    
    func messageSwitchView(view: MessageSwitchView, shouldSelectSlotAtIndex index: Int) -> Bool {
        if UpgradeManager.sharedInstance.isProVersion() {
            return true
        }
        if index < Constants.NumberOfFreeAffirmations {
            return true
        } else {
            showUpgradeAppMessage()
            return false
        }
    }
    
    func shouldActivateReceivingTimeViewInMessageSwitchView(view: MessageSwitchView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func didFinishPickingReceivingTimeInMessageSwitchView(view: MessageSwitchView) {
        if messageSwitchView.receiveTime != ReceiveTime.AnyTime {
            if var affirmations = affirmationsWithReceiveTime(messageSwitchView.receiveTime) {
                if let selectedAfi = selectedAffirmation where affirmations.contains(selectedAfi) {
                    affirmations.removeAtIndex(affirmations.indexOf(selectedAfi)!)
                }
                if affirmations.count > 0 {
                    showReceiveTimeDuplicationWarning()
                    resetSelectedSlot()
                } else {
                    saveChanges()
                }
            }
        } else {
            saveChanges()
        }
        if !TutorialManager.sharedInstance.completed {
            TutorialManager.sharedInstance.nextStep()
        }
    }
    
    func showReceiveTimeDuplicationWarning() {
        tutorialViewController?.showMessage(ReceiveTimeConfirmationQuestion(messageSwitchView.receiveTime), disappear: TutorialManager.sharedInstance.completed)
    }
    
    func resetSelectedSlot() {
        if selectedAffirmation != nil {
            fillAffirmationWithNumber((selectedAffirmation?.number)!)
        } else {
            messageSwitchView.receiveTime = .AnyTime
        }
    }
    
    private func saveChanges() {
        if selectedAffirmation == nil {
            saveAffirmation()
        } else if let affirmation = selectedAffirmation where affirmation.receiveTime != messageSwitchView.receiveTime {
            affirmation.receiveTime = messageSwitchView.receiveTime
            if !APIManager.sharedInstance.reachability.isReachable() {
                tutorialViewController?.showNoInternetConnection()
            }
        }
    }
    
    func messageSwitchView(view: MessageSwitchView, longPressAtItem index: Int) {
        self.deleteItem(atIndex: index);
    }
    
    func messageSwitchView(view: MessageSwitchView, itemAvailable index: Int) -> Bool {
        return index < Constants.NumberOfFreeAffirmations ? true : false
    }
}

// MARK: - UITextViewDelegate

extension AffirmationsViewController: UITextViewDelegate {
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let length = textView.text.characters.count + text.characters.count
        
        if text == "\n" {
            textView.resignFirstResponder()
            saveAffirmation()
            return false
        }
        
        if length >= Affirmation.MaxTextLength {
            let warningMessage = "You can only use \(Affirmation.MaxTextLength) characters for each affirmation. Please modify accordingly."
            if !TutorialManager.sharedInstance.completed {
                tutorialViewController!.showWarningMessage(warningMessage, disappear: true)
            } else {
                tutorialViewController?.showMessage(PlainMessage(text: warningMessage), disappear:true)
            }
            return false
        }
        return true
    }
}
