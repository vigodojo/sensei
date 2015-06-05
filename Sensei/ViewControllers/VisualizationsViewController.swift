//
//  VisualizationsViewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/5/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData

class VisualizationsViewController: UserMessageViewController {
   
    private struct Constants {
        static let VisuaizationCellReuseIdentifier = "VisualizationCollectionViewCell"
        static let NumberOfVisualizations = 5
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "VISUALIZATIONS"
        }
    }
    
    override var messageSwitchCell: MessageSwitchCollectionViewCell? {
        didSet {
            messageSwitchCell?.delegate = self
        }
    }
    
    private var visualizationCell: VisualizationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectVisualizationWithNumber(NSNumber(integer:0))
            }
        }
    }
    
    private lazy var visualizationFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: Visualization.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    var isTutorialOn = true
    
    var didChangeImage = false
    
    // MARK: - UserMessageViewController
    
    override func setupItems() {
        super.setupItems()
        items.append(Item(reuseIdentifier: Constants.VisuaizationCellReuseIdentifier, height: remainingHeight))
    }
    
    override func fetchUserMessages() {
        var error: NSError? = nil
        if !visualizationFetchedResultController.performFetch(&error) {
            println("Failed to fetch user messages with error: \(error)")
        }
    }
    
    override func hasChangesBeenMade() -> Bool {
        if let index = messageSwitchCell?.selectedSlot {
            let receiveTime = messageSwitchCell?.reseiveTime ?? ReceiveTime.Morning
            let text = visualizationCell?.text ?? ""
            if let visualization = visualizationWithNumber(index) {
                return hasVisualizationBeenChanged(visualization, newText: text, newReceiveTime: receiveTime)
            }
            return !text.isEmpty || didChangeImage
        }
        return false
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is VisualizationCollectionViewCell {
            visualizationCell = (cell as? VisualizationCollectionViewCell)
            visualizationCell?.delegate = self
        } 
        return cell
    }
        
    // MARK: - Private
    
    private func hasVisualizationBeenChanged(visualization: Visualization, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return visualization.text != newText || visualization.receiveTime != newReceiveTime || didChangeImage
    }
    
    private func selectVisualizationWithNumber(number: NSNumber) {
        didChangeImage = false
        messageSwitchCell?.selectedSlot = number.integerValue
        if let visualization = visualizationWithNumber(number) {
            messageSwitchCell?.reseiveTime = visualization.receiveTime
            visualizationCell?.text = visualization.text
            visualizationCell?.imageView.image = visualization.picture
            visualizationCell?.editButtonHidden = false
        } else {
            resetVisualizationCell()
        }
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }
    
    private func visualizationWithNumber(number: NSNumber) -> Visualization? {
        if let fetchedObjects = visualizationFetchedResultController.fetchedObjects as? [Visualization] {
            let filteredMessages = fetchedObjects.filter(){ $0.number.compare(number) == .OrderedSame }
            return filteredMessages.first
        }
        return nil
    }
    
    private func presentImagePickerControllerWithSourceType(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func saveVisualization() {
        let index = messageSwitchCell?.selectedSlot
        let receiveTime = messageSwitchCell?.reseiveTime
        let text = visualizationCell?.text
        let image = visualizationCell?.imageView.image
        if let index = index, receiveTime = receiveTime, text = text, image = image {
            if let visualization = visualizationWithNumber(index) {
                if visualization.text != text || visualization.receiveTime != receiveTime || visualization.picture != image {
                    visualization.text = text
                    visualization.picture = image
                    visualization.receiveTime = receiveTime
                    CoreDataManager.sharedInstance.saveContext()
                }
            } else  {
                Visualization.createVisualizationWithNumber(index, text: text, receiveTime: receiveTime, picture: image)
                CoreDataManager.sharedInstance.saveContext()
            }
        }
    }
    
    private func deleteVisualization() {
        if let index = messageSwitchCell?.selectedSlot, visualization = visualizationWithNumber(index) {
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(visualization)
            CoreDataManager.sharedInstance.saveContext()
            resetVisualizationCell()
        }
    }

    private func resetVisualizationCell() {
        messageSwitchCell?.reseiveTime = .Morning
        visualizationCell?.text = ""
        visualizationCell?.imageView.image = nil
        visualizationCell?.editButtonHidden = true
    }
    
    // MARK: - IBAction
    
    @IBAction func visualizationImageViewTap(sender: UITapGestureRecognizer) {
        println("Tap Image")
    }
}

// MARK: - MessageSwitchCollectionViewCellDelegate

extension VisualizationsViewController: MessageSwitchCollectionViewCellDelegate {
    
    func messageSwitchCollectionViewCellDidSave(cell: MessageSwitchCollectionViewCell) {
        saveVisualization()
    }
    
    func numberOfSlotsInMessageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell) -> Int {
        return Constants.NumberOfVisualizations
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectSlotAtIndex index: Int) {
        selectVisualizationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, isSlotEmptyAtIndex index: Int) -> Bool {
        return visualizationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        println("\(self) ReceiveTime \(receiveTime.rawValue)")
    }
}

// MARK: - VisualizationCollectionViewCellDelegate

extension VisualizationsViewController: VisualizationCollectionViewCellDelegate {
    
    func visualizationCollectionViewCellDidTakePhoto(cell: VisualizationCollectionViewCell) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.presentImagePickerControllerWithSourceType(UIImagePickerControllerSourceType.Camera)
        }))
        alert.addAction(UIAlertAction(title: "Select Picture", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.presentImagePickerControllerWithSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func visualizationCollectionViewCellDidBeginEditing(cell: VisualizationCollectionViewCell) {
        let index = items.find { $0.reuseIdentifier == UserMessageViewController.Constants.MessageSwitchCellNibName }
        if let index = index {
            items.removeAtIndex(index)
            collectionView.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
            }, completion: { (finished) -> Void in
                self.visualizationCell?.textView.becomeFirstResponder()
            })
        }
    }
    
    func visualizationCollectionViewCellDidEndEditing(cell: VisualizationCollectionViewCell) {
        let index = isTutorialOn ? 2 : 1
        items.insert(Item(reuseIdentifier: UserMessageViewController.Constants.MessageSwitchCellNibName, height: remainingHeight), atIndex: index)
        collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
        visualizationCell?.editButtonHidden = !hasChangesBeenMade()
    }
    
    func visualizationCollectionViewCellDidDelete(cell: VisualizationCollectionViewCell) {
        deleteVisualization()
    }
    
    func visualizationCollectionViewCellDidChange(cell: VisualizationCollectionViewCell) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension VisualizationsViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            visualizationCell?.imageView.image = image
            didChangeImage = true
            messageSwitchCell?.saveButtonHidden = false
            picker.dismissViewControllerAnimated(true, completion: nil)
            visualizationCell?.mode = VisualizationCollectionViewCellMode.Editing
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension VisualizationsViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let visualization = anObject as? Visualization {
            switch type {
                case .Insert:
                    messageSwitchCell?.reloadSlotAtIndex(visualization.number.integerValue)
                    let number = ((visualization.number.integerValue + 1) % Constants.NumberOfVisualizations)
                    selectVisualizationWithNumber(number)
                    APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
                case .Update:
                    let number = ((visualization.number.integerValue + 1) % Constants.NumberOfVisualizations)
                    selectVisualizationWithNumber(number)
                    APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
                case .Delete:
                    messageSwitchCell?.reloadSlotAtIndex(visualization.number.integerValue)
                    messageSwitchCell?.selectedSlot = visualization.number.integerValue
                    APIManager.sharedInstance.deleteVisualization(visualization, handler: nil)
                default:
                    break
                }
            messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        }
    }
}

extension Array {
    
    func find(includedElement: T -> Bool) -> Int? {
        for (idx, element) in enumerate(self) {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
}
