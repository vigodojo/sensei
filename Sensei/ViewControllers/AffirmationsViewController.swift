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
        static let AffirmationCellReuseIdentifier = "AffirmationCollectionViewCell"
        static let AffirmationCellHeight: CGFloat = 86
        static let NumberOfAffirmations = 6
        static let EstimatedKeyboardHeight: CGFloat = 224
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "AFFIRMATIONS"
        }
    }
    
    override var messageSwitchCell: MessageSwitchCollectionViewCell? {
        didSet {
            messageSwitchCell?.delegate = self
        }
    }
    
    private var affirmationCell: AffirmationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectAffirmationWithNumber(NSNumber(integer:0))
            }
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
    
    private var affirmationCellHeight: CGFloat {
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds) - (navigationItemsHeight + UserMessageViewController.Constants.MessageSwitchCellHeight + keyboardHeight)
        return max(height, Constants.AffirmationCellHeight)
    }

    
    // MARK: - UserMessageViewController
    
    override func setupItems() {
        super.setupItems()
        items.append(Item(reuseIdentifier: Constants.AffirmationCellReuseIdentifier, height: affirmationCellHeight))
    }
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            if !self.affirmationsFetchedResultController.performFetch(&error) {
                println("Failed to fetch user messages with error: \(error)")
            }

            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.messageSwitchCell?.reloadSlots()
                self.selectAffirmationWithNumber(NSNumber(integer:0))
            })
        })
    }
    
    override func hasChangesBeenMade() -> Bool {
        if let index = messageSwitchCell?.selectedSlot {
            let receiveTime = messageSwitchCell?.reseiveTime ?? ReceiveTime.Morning
            let text = affirmationCell?.text ?? ""
            if let affirmation = affirmationWithNumber(index) {
                return hasAffirmationBeenChanged(affirmation, newText: text, newReceiveTime: receiveTime)
            }
            return !text.isEmpty
        }
        return false
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is AffirmationCollectionViewCell {
            affirmationCell = (cell as? AffirmationCollectionViewCell)
            affirmationCell?.delegate = self
        }
        return cell
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if let textView = messageSwitchCell?.receiveTimeTextView where textView.isFirstResponder() {
            return;
        }
        if keyboardHeight != size.height {
            keyboardHeight = size.height
            items.last!.height = affirmationCellHeight
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            affirmationCell?.updateTextViewHeight()
        }
        super.keyboardWillShowWithSize(size, animationDuration: animationDuration, animationOptions: animationOptions)
    }
    
    // MARK: - Private
    
    private func hasAffirmationBeenChanged(affirmation: Affirmation, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return affirmation.text != newText || affirmation.receiveTime != newReceiveTime
    }
    
    private func selectAffirmationWithNumber(number: NSNumber) {
        messageSwitchCell?.selectedSlot = number.integerValue
        if let affirmation = affirmationWithNumber(number) {
            messageSwitchCell?.reseiveTime = affirmation.receiveTime
            affirmationCell?.text = affirmation.text
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
        let index = messageSwitchCell?.selectedSlot
        let receiveTime = messageSwitchCell?.reseiveTime
        let text = affirmationCell?.text
        if let index = index, receiveTime = receiveTime, text = text {
            if let affirmation = affirmationWithNumber(index) {
                if text.isEmpty {
                    CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(affirmation)
                    CoreDataManager.sharedInstance.saveContext()
                } else if affirmation.text != text || affirmation.receiveTime != receiveTime {
                    affirmation.text = text
                    affirmation.receiveTime = receiveTime
                    CoreDataManager.sharedInstance.saveContext()
                }
            } else if !text.isEmpty {
                Affirmation.createAffirmationNumber(index, text: text, receiveTime: receiveTime)
                CoreDataManager.sharedInstance.saveContext()
            }
        }
    }
    
    private func deleteAffirmation() {
        if let index = messageSwitchCell?.selectedSlot, affirmation = affirmationWithNumber(index) {
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(affirmation)
            CoreDataManager.sharedInstance.saveContext()
        }
        resetInfo()
    }
    
    private func resetInfo() {
        messageSwitchCell?.reseiveTime = .Morning
        affirmationCell?.text = ""
        messageSwitchCell?.saveButtonHidden = true
    }
}

// MARK: - MessageSwitchCollectionViewCellDelegate

extension AffirmationsViewController: MessageSwitchCollectionViewCellDelegate {
    
    func messageSwitchCollectionViewCellDidSave(cell: MessageSwitchCollectionViewCell) {
        saveAffirmation()
        affirmationCell?.textView.resignFirstResponder()
    }
    
    func numberOfSlotsInMessageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell) -> Int {
        return Constants.NumberOfAffirmations
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectSlotAtIndex index: Int) {
        selectAffirmationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, isSlotEmptyAtIndex index: Int) -> Bool {
        return affirmationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        println("\(self) ReceiveTime \(receiveTime.rawValue)")
    }
}

// MARK: - AffirmationCollectionViewCellDelegate

extension AffirmationsViewController: AffirmationCollectionViewCellDelegate {
    
    func affirmationCollectionViewCellDidChange(cell: AffirmationCollectionViewCell) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }
    
    func affirmationCollectionViewCellDidDelete(cell: AffirmationCollectionViewCell) {
        deleteAffirmation()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension AffirmationsViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let affirmation = anObject as? Affirmation {
            switch type {
                case .Insert:
                    messageSwitchCell?.reloadSlotAtIndex(affirmation.number.integerValue)
                    let number = ((affirmation.number.integerValue + 1) % Constants.NumberOfAffirmations)
                    selectAffirmationWithNumber(number)
                    APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
                case .Update:
                    let number = ((affirmation.number.integerValue + 1) % Constants.NumberOfAffirmations)
                    selectAffirmationWithNumber(number)
                    APIManager.sharedInstance.saveAffirmation(affirmation, handler: nil)
                case .Delete:
                    messageSwitchCell?.reloadSlotAtIndex(affirmation.number.integerValue)
                    messageSwitchCell?.selectedSlot = affirmation.number.integerValue
                    APIManager.sharedInstance.deleteAffirmation(affirmation, handler: nil)
                default:
                    break
            }
            messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        }
    }
}
