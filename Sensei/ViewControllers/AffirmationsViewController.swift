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
        static let AffirmationCellHeight: CGFloat = 110
        static let NumberOfAffirmations = 6
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
    
    // MARK: - UserMessageViewController
    
    override func setupItems() {
        super.setupItems()
        items.append(Item(reuseIdentifier: Constants.AffirmationCellReuseIdentifier, height: Constants.AffirmationCellHeight))
    }
    
    override func fetchUserMessages() {
        var error: NSError? = nil
        if !affirmationsFetchedResultController.performFetch(&error) {
            println("Failed to fetch user messages with error: \(error)")
        }
    }
    
    override func hasChangesBeenMade() -> Bool {
        if let index = messageSwitchCell?.selectedSlot {
            let receiveTime = messageSwitchCell?.reseiveTime ?? ReceiveTime.Morning
            let text = affirmationCell?.textView.text ?? ""
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
    
    // MARK: - Private
    
    private func hasAffirmationBeenChanged(affirmation: Affirmation, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return affirmation.text != newText || affirmation.receiveTime != newReceiveTime
    }
    
    private func selectAffirmationWithNumber(number: NSNumber) {
        messageSwitchCell?.selectedSlot = number.integerValue
        if let affirmation = affirmationWithNumber(number) {
            messageSwitchCell?.reseiveTime = affirmation.receiveTime
            affirmationCell?.textView.text = affirmation.text
        } else {
            messageSwitchCell?.reseiveTime = .Morning
            affirmationCell?.textView.text = ""
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
        let text = affirmationCell?.textView.text
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
