//
//  VisualizationsViewController.swift
//  Sensei
//
//  Created by Sauron Black on 6/5/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class VisualizationsViewController: UserMessageViewController {
   
    private struct Constants {
        static let VisuaizationCellReuseIdentifier = "VisualizationCollectionViewCell"
        static let NumberOfVisualizations = 5
    }
    
    private let DeleteConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to delete this Visualisation?")
    
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
    
    private var visualizationCellHeight: CGFloat {
        var height = CGRectGetHeight(UIScreen.mainScreen().bounds) - (navigationItemsHeight + UserMessageViewController.Constants.MessageSwitchCellHeight)
        if let tutorialViewController = tutorialViewController where !tutorialViewController.tutorialHidden {
           height -= tutorialViewController.tutorialContainerHeight
        }
        return height
    }
    
    private var didChangeImage = false
    private var visualisationCellAttributes: Item?
    
    // MARK: - UserMessageViewController
    
    override func setupItems() {
        super.setupItems()
        visualisationCellAttributes = Item(reuseIdentifier: Constants.VisuaizationCellReuseIdentifier, height: visualizationCellHeight)
        contentItems.append(visualisationCellAttributes!)
    }
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            if !self.visualizationFetchedResultController.performFetch(&error) {
                println("Failed to fetch user messages with error: \(error)")
            }
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.messageSwitchCell?.reloadSlots()
                self.selectVisualizationWithNumber(NSNumber(integer:0))
            })
        })
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
    
    // MARK: - Tutorial
    
    override func handleTutorialMoving() {
        let height = visualizationCellHeight
        visualisationCellAttributes?.height = height
        let cellBounds = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(collectionView.frame), height: height))
        let imageContainerBounds = UIEdgeInsetsInsetRect(cellBounds, VisualizationCollectionViewCell.ImageContainerEdgeInsets)
        UIView.animateWithDuration(AnimationDuration, animations: { () -> Void in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.setCollectionViewLayout(self.collectionView.collectionViewLayout, animated: true)
            self.visualizationCell?.updateImageContainerViewWithBounds(imageContainerBounds)
        })
    }
    
    override func handleYesAnswerNotification(notification: NSNotification) {
        deleteVisualization()
        visualizationCell?.mode = .Default
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
            visualizationCell?.image = visualization.picture
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
        let image = visualizationCell?.image
        let insideRect = visualizationCell?.imageView.bounds
        if let index = index, receiveTime = receiveTime, text = text, image = image, insideRect = insideRect {
            
            let number = ((index + 1) % Constants.NumberOfVisualizations)
            selectVisualizationWithNumber(number)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
                if let visualization = self.visualizationWithNumber(index) {
                    if visualization.text != text || visualization.receiveTime != receiveTime || visualization.picture != image {
                        visualization.text = text
                        visualization.picture = image
                        visualization.receiveTime = receiveTime
                        visualization.scaledFontSize = Visualization.scaledFontSizeForImageWithSize(image.size, text: text, insideRect: insideRect)
                        CoreDataManager.sharedInstance.saveContext()
                    }
                } else  {
                    let visualisation = Visualization.createVisualizationWithNumber(index, text: text, receiveTime: receiveTime, picture: image)
                    visualisation.scaledFontSize = Visualization.scaledFontSizeForImageWithSize(image.size, text: text, insideRect: insideRect)
                    CoreDataManager.sharedInstance.saveContext()
                }
            }
        }
    }
    
    private func deleteVisualization() {
        if let index = messageSwitchCell?.selectedSlot, visualization = visualizationWithNumber(index) {
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(visualization)
            CoreDataManager.sharedInstance.saveContext()
        }
        resetVisualizationCell()
        didChangeImage = false
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }

    private func resetVisualizationCell() {
        messageSwitchCell?.reseiveTime = .Morning
        visualizationCell?.text = ""
        visualizationCell?.image = nil
        visualizationCell?.editButtonHidden = true
    }
    
    private func showVisualizationInPreview() {
        if let imageView = visualizationCell?.imageView, image = imageView.image, text = visualizationCell?.text {
            let scaledFontSize = Visualization.scaledFontSizeForImageWithSize(image.size, text: text, insideRect: imageView.bounds)
            let imagePreviewController = TextImagePreviewController.imagePreviewControllerWithImage(image)
            imagePreviewController.attributedText = NSAttributedString(string: text, attributes: Visualization.attributesForFontWithSize(scaledFontSize))
            self.presentViewController(imagePreviewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func visualizationImageViewTap(sender: UITapGestureRecognizer) {
        showVisualizationInPreview()
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
        let index = 0
        contentItems.removeAtIndex(index)
        if let item = visualisationCellAttributes {
            item.height = cell.minRequiredHeight
        }
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
            self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 1)])
        }, completion: { (finished) -> Void in
            self.visualizationCell?.textView.becomeFirstResponder()
        })
    }
    
    func visualizationCollectionViewCellDidEndEditing(cell: VisualizationCollectionViewCell) {
        let index = 0
        if let item = visualisationCellAttributes {
            item.height = visualizationCellHeight
        }
        contentItems.insert(Item(reuseIdentifier: UserMessageViewController.Constants.MessageSwitchCellNibName, height: UserMessageViewController.Constants.MessageSwitchCellHeight), atIndex: index)
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 1)])
        }, completion: nil)
        showVisualizationInPreview()
    }
    
    func visualizationCollectionViewCellDidDelete(cell: VisualizationCollectionViewCell) {
        tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
    }
    
    func visualizationCollectionViewCellDidChange(cell: VisualizationCollectionViewCell) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension VisualizationsViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            visualizationCell?.image = image.upOrientedImage
            didChangeImage = true
            messageSwitchCell?.saveButtonHidden = false
            visualizationCell?.editButtonHidden = false
            dismissViewControllerAnimated(true, completion: nil)
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
                    APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
                case .Update:
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
