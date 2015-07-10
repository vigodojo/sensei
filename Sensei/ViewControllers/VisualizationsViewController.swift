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
        static let MessageSwitchViewHeight: CGFloat = 100
    }

    private let DeleteConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to delete this Visualisation?")
    
    override weak var navigationView: NavigationView! {
        didSet {
            navigationView.titleLabel.text = "VISUALIZATIONS"
        }
    }
    
    @IBOutlet weak var scrollViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageSwitchViewHeightConstraint: NSLayoutConstraint!
    override weak var messageSwitchView: MessageSwitchView! {
        didSet {
            messageSwitchView.delegate = self
        }
    }
    
    @IBOutlet var visualisationView: VisualisationView! {
        didSet {
            visualisationView.delegate = self
        }
    }
    
    private lazy var visualizationFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: Visualization.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    private var scrollViewBottomSpace: CGFloat {
        var space = CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight(navigationView.frame) - visualisationView.minRequiredHeight
        if let tutorialViewController = tutorialViewController where !tutorialViewController.tutorialHidden {
            space -= tutorialViewController.tutorialContainerHeight
        }
        return space
    }
    
    private var hasDisplayedContent: Bool {
        return selectedVisualization != nil || visualisationView.image != nil
    }
    
    private var selectedVisualization: Visualization?
    
    private var didChangeImage = false
    
    // MARK: - UserMessageViewController
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            if !self.visualizationFetchedResultController.performFetch(&error) {
                println("Failed to fetch user messages with error: \(error)")
            }
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.messageSwitchView?.reloadSlots()
                self.selectVisualizationWithNumber(NSNumber(integer:0))
            })
        })
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if messageSwitchView.receiveTimeTextView.isFirstResponder() {
            return;
        }
        let aScrollViewBottomSpace = scrollViewBottomSpace
        let bottomOffset = max(0, size.height - aScrollViewBottomSpace)
        view.layoutIfNeeded()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomOffset, right: 0)
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: animationOptions, animations: { [weak self] in
            self?.messageSwitchViewHeightConstraint.constant = 0
            self?.scrollViewBottomSpaceConstraint.constant = aScrollViewBottomSpace
            self?.scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        view.layoutIfNeeded()
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [weak self] in
            self?.messageSwitchViewHeightConstraint.constant = Constants.MessageSwitchViewHeight
            self?.scrollViewBottomSpaceConstraint.constant = 0
            self?.scrollView.contentInset = UIEdgeInsetsZero
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Tutorial
    
    override func handleTutorialMoving() {
        if visualisationView.mode == .Editing {
            let aScrollViewBottomSpace = scrollViewBottomSpace
            let delta = self.scrollViewBottomSpaceConstraint.constant - aScrollViewBottomSpace
            let bottomOffset = scrollView.contentInset.bottom + delta
            view.layoutIfNeeded()
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomOffset, right: 0)
            UIView.animateWithDuration(AnimationDuration, animations: { [weak self] in
                self?.scrollViewBottomSpaceConstraint.constant = aScrollViewBottomSpace
                self?.scrollView.contentOffset = CGPoint(x: 0, y: bottomOffset)
                self?.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func handleYesAnswerNotification(notification: NSNotification) {
        deleteVisualization()
        visualisationView?.mode = .Default
    }
        
    // MARK: - Private
    
    private func hasVisualizationBeenChanged(visualization: Visualization, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return visualization.text != newText || visualization.receiveTime != newReceiveTime || didChangeImage
    }
    
    private func selectVisualizationWithNumber(number: NSNumber) {
        didChangeImage = false
        messageSwitchView.selectedSlot = number.integerValue
        if let visualisation = visualizationWithNumber(number) {
            messageSwitchView.receiveTime = visualisation.receiveTime
            visualisationView.configureWithText(visualisation.text, image: visualisation.picture)
            selectedVisualization = visualisation
        } else {
            resetVisualizationCell()
        }
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
        if let image = visualisationView.image, index = messageSwitchView.selectedSlot {
            let receiveTime = messageSwitchView.receiveTime
            let text = visualisationView.text
            let fontSize = visualisationView.currentFontSize
            let insideRect = visualisationView.imageView.bounds
            let wasImageChanged = didChangeImage
            let currentVisualisation = selectedVisualization
            
            let number = ((index + 1) % Constants.NumberOfVisualizations)
            selectVisualizationWithNumber(number)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                if let visualisation = currentVisualisation {
                    if visualisation.text != text || visualisation.receiveTime != receiveTime || wasImageChanged {
                        visualisation.text = text
                        visualisation.picture = image
                        visualisation.receiveTime = receiveTime
                        visualisation.scaledFontSize = Visualization.scaledFontSizeForFontSize(fontSize, imageSize: image.size, insideRect: insideRect)
                    }
                } else {
                    let visualisation = Visualization.createVisualizationWithNumber(index, text: text, receiveTime: receiveTime, picture: image)
                    visualisation.scaledFontSize = Visualization.scaledFontSizeForFontSize(fontSize, imageSize: image.size, insideRect: insideRect)
                }
            }
        }
    }
    
    private func deleteVisualization() {
        if let visualisation = selectedVisualization {
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(visualisation)
        }
        resetVisualizationCell()
        didChangeImage = false
    }

    private func resetVisualizationCell() {
        messageSwitchView.receiveTime = .Morning
        visualisationView.configureWithText("", image: nil)
        selectedVisualization = nil
    }
    
    private func showVisualizationInPreview() {
        if let image = visualisationView.image {
            let text = visualisationView.text
            let scaledFontSize = Visualization.scaledFontSizeForFontSize(visualisationView.currentFontSize, imageSize: image.size, insideRect: visualisationView.imageView.bounds)
            let imagePreviewController = TextImagePreviewController.imagePreviewControllerWithImage(image)
            imagePreviewController.attributedText = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(scaledFontSize))
            self.presentViewController(imagePreviewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func visualizationImageViewTap(sender: UITapGestureRecognizer) {
        showVisualizationInPreview()
    }
}

// MARK: - MessageSwitchViewDelegate

extension VisualizationsViewController: MessageSwitchViewDelegate {
    
    func numberOfSlotsInMessageSwitchView(view: MessageSwitchView) -> Int {
        return Constants.NumberOfVisualizations
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectSlotAtIndex index: Int) {
        selectVisualizationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchView(view: MessageSwitchView, isSlotEmptyAtIndex index: Int) -> Bool {
        return visualizationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectReceiveTime receiveTime: ReceiveTime) { }
    
    func shouldActivateReceivingTimeViewInMessageSwitchView(view: MessageSwitchView) -> Bool {
        return true
    }
    
    func didFinishPickingReceivingTimeInMessageSwitchView(view: MessageSwitchView) {
        if let visualisation = selectedVisualization where visualisation.receiveTime != messageSwitchView.receiveTime {
            visualisation.receiveTime = messageSwitchView.receiveTime
        }
    }
}

// MARK: - VisualizationViewDelegate

extension VisualizationsViewController: VisualizationViewDelegate {
    
    func visualizationViewDidTakePhoto(cell: VisualisationView) {
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
    
    func visualizationViewDidBeginEditing(cell: VisualisationView) {
        
    }
    
    func visualizationViewDidEndEditing(cell: VisualisationView) {
        showVisualizationInPreview()
        visualisationView.editButtonHidden = !hasDisplayedContent
        saveVisualization()
    }
    
    func visualizationViewDidDelete(cell: VisualisationView) {
        tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
    }
    
    func minPossibleHeightForVisualizationView(view: VisualisationView) -> CGFloat {
        var height = CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight(navigationView.frame) - CGRectGetHeight(messageSwitchView.frame)
        if let tutorialViewController = tutorialViewController {
            height -= tutorialViewController.tutorialContainerHeight
        }
        return height
    }
}

// MARK: - UIImagePickerControllerDelegate

extension VisualizationsViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            visualisationView.configureWithText(selectedVisualization?.text ?? "", image: image.upOrientedImage.fullScreenImage)
            didChangeImage = true
            dismissViewControllerAnimated(true) { [weak self] in
                self?.visualisationView.mode = VisualizationViewMode.Editing
            }
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
                    messageSwitchView.reloadSlotAtIndex(visualization.number.integerValue)
                    APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
                case .Update:
                    APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
                case .Delete:
                    messageSwitchView.reloadSlotAtIndex(visualization.number.integerValue)
                    messageSwitchView.selectedSlot = visualization.number.integerValue
                    APIManager.sharedInstance.deleteVisualization(visualization, handler: nil)
                default:
                    break
            }
        }
    }

}
