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

class VisualizationsViewController: UserMessageViewController, NSFetchedResultsControllerDelegate {
   
    private struct Constants {
        static let VisuaizationCellReuseIdentifier = "VisualizationCollectionViewCell"
        static let NumberOfVisualizations = 5
        static let NumberOfFreeVisualizations = 1
        static let MessageSwitchViewHeight: CGFloat = 100
        static let VisualizationMessageSwitchViewHeight: CGFloat = 110
    }
    
    private struct ControlNames {
        static let CameraButton = "CameraButton"
        static let EditButton = "EditButton"
        static let MessageSwitchViewLongPress = "MessageSwitchViewLongPress"
    }

    private let DeleteConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to delete this Visualisation?")
    
    private func ReceiveTimeConfirmationQuestion(receiveTime: ReceiveTime) -> PlainMessage {
        return PlainMessage(text: "There can be only one visualization set for \(receiveTime.description.lowercaseString).")
    }
    
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
    
    override var upgradeAppMessage: String {
        return "You can only have one active visualization with the free version of this app, please upgrade to unlock all the slots"
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
    
    private var itemToDelete: Int?;

    private var swipeNextGesture: UISwipeGestureRecognizer?
    private var swipePrevGesture: UISwipeGestureRecognizer?
    private var shouldShowInstruction: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swipeNextGesture = UISwipeGestureRecognizer(target: self, action: #selector(VisualizationsViewController.showNextSlot(_:)))
        swipeNextGesture!.direction = .Left
        self.view.addGestureRecognizer(swipeNextGesture!)
        
        swipePrevGesture = UISwipeGestureRecognizer(target: self, action: #selector(VisualizationsViewController.showPrevSlot(_:)))
        swipePrevGesture!.direction = .Right
        self.view.addGestureRecognizer(swipePrevGesture!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VisualizationsViewController.didUpgradeToPro(_:)), name: UpgradeManager.Notifications.DidUpgrade, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if TutorialManager.sharedInstance.completed && shouldShowInstruction {
            shouldShowInstruction = false
            self.tutorialViewController!.showNextVisInstruction()
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

    // MARK: SwipeGestureRecognizer
    
    func showNextSlot(recognizer: UISwipeGestureRecognizer) {
        let indexPath = NSIndexPath(forItem: messageSwitchView.selectedSlot! + 1, inSection: 0)
        if !UpgradeManager.sharedInstance.isProVersion() && indexPath.item >= Constants.NumberOfFreeVisualizations {
            if TutorialManager.sharedInstance.completed {
                showUpgradeAppMessage()
            }
            return
        }
        if indexPath.item >= Constants.NumberOfVisualizations {
            return
        }
        messageSwitchView.slotsCollectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
        messageSwitchView.collectionView(messageSwitchView.slotsCollectionView, didSelectItemAtIndexPath: indexPath)
    }
    
    func showPrevSlot(recognizer: UISwipeGestureRecognizer) {
        let indexPath = NSIndexPath(forItem: messageSwitchView.selectedSlot!-1, inSection: 0)
        if indexPath.item < 0 {
            return
        }
        messageSwitchView.slotsCollectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
        messageSwitchView.collectionView(messageSwitchView.slotsCollectionView, didSelectItemAtIndexPath: indexPath)
    }
    
    // MARK: - UserMessageViewController
    
    override func fetchUserMessages() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { [unowned self] () -> Void in
            var error: NSError? = nil
            do {
                try self.visualizationFetchedResultController.performFetch()
            } catch let error1 as NSError {
                error = error1
                print("Failed to fetch user messages with error: \(error)")
            } catch {
                fatalError()
            }
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.messageSwitchView?.reloadSlots()
                self.selectVisualizationWithNumber(NSNumber(integer:0))
            })
        })
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        swipeNextGesture?.enabled = false
        swipePrevGesture?.enabled = false

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
        swipeNextGesture?.enabled = true
        swipePrevGesture?.enabled = true

        view.layoutIfNeeded()
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [weak self] in
            self?.messageSwitchViewHeightConstraint.constant = Constants.VisualizationMessageSwitchViewHeight
            self?.scrollViewBottomSpaceConstraint.constant = 0
            self?.scrollView.contentInset = UIEdgeInsetsZero
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Tutorial
    
    override func enableControls(controlNames: [String]?) {
        super.enableControls(controlNames)
        visualisationView.cameraButton.userInteractionEnabled = controlNames?.contains(ControlNames.CameraButton) ?? true
        visualisationView.editButton.userInteractionEnabled = controlNames?.contains(ControlNames.EditButton) ?? true
        
        messageSwitchView.longPressGesture.enabled = controlNames?.contains(ControlNames.EditButton) == true || controlNames?.contains(ControlNames.MessageSwitchViewLongPress) == true ?? true
        messageSwitchView.slotsCollectionView.userInteractionEnabled = messageSwitchView.longPressGesture.enabled
        
        swipeNextGesture?.enabled = messageSwitchView.slotsCollectionView.userInteractionEnabled
        swipePrevGesture?.enabled = messageSwitchView.slotsCollectionView.userInteractionEnabled
    }
    
    // MARK: - Tutorial View
    
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
        if itemToDelete != nil {
            deleteVisualization()
            visualisationView?.mode = .Default
        }
    }
    
    override func handleNoAnswerNotification(notification: NSNotification) {
//        if itemToDelete == nil && selectedVisualization != nil {
//            fillVisualisationWithNumber((selectedVisualization?.number)!)
//        }
    }
    
    // MARK: - Private
    
    private func hasVisualizationBeenChanged(visualization: Visualization, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return visualization.text != newText || visualization.receiveTime != newReceiveTime || didChangeImage
    }
    
    private func fillVisualisationWithNumber(number: NSNumber) {
        didChangeImage = false
        if let visualisation = visualizationWithNumber(number) {
            messageSwitchView.receiveTime = visualisation.receiveTime
            visualisationView.configureWithText(visualisation.text, image: visualisation.picture, number: NSNumber(integer: number.integerValue + 1))
            selectedVisualization = visualisation
        } else {
            resetVisualizationCell()
        }
    }
    
    private func selectVisualizationWithNumber(number: NSNumber) {
        if let selectedSlot = messageSwitchView.selectedSlot where selectedSlot == number.integerValue {
            return
        }
        messageSwitchView.selectedSlot = number.integerValue
        fillVisualisationWithNumber(number)
    }
    
    private func visualizationWithNumber(number: NSNumber) -> Visualization? {
        if let fetchedObjects = visualizationFetchedResultController.fetchedObjects as? [Visualization] {
            let filteredMessages = fetchedObjects.filter(){ $0.number.compare(number) == .OrderedSame }
            return filteredMessages.first
        }
        return nil
    }
    
    private func visualizationsWithReceiveTime(receiveTime: ReceiveTime) -> [Visualization]? {
        if let fetchedObjects = visualizationFetchedResultController.fetchedObjects as? [Visualization] {
            let filteredMessages = fetchedObjects.filter(){ $0.receiveTime == receiveTime }
            return filteredMessages
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

            dispatch_async(dispatch_get_main_queue()) {
                if let visualisation = currentVisualisation {
                    if visualisation.text != text || visualisation.receiveTime != receiveTime || wasImageChanged {
                        visualisation.text = text
                        visualisation.picture = image
                        visualisation.receiveTime = receiveTime
                        visualisation.scaledFontSize = Visualization.scaledFontSizeForFontSize(fontSize, imageSize: image.size, insideRect: insideRect)
                        if !APIManager.sharedInstance.reachability.isReachable() {
                            visualisation.updatedOffline = NSNumber(bool: true)
                        }
                    }
                } else {
                    let visualisation = Visualization.createVisualizationWithNumber(index, text: text, receiveTime: receiveTime, picture: image)
                    visualisation.scaledFontSize = Visualization.scaledFontSizeForFontSize(fontSize, imageSize: image.size, insideRect: insideRect)
                    if !APIManager.sharedInstance.reachability.isReachable() {
                        visualisation.updatedOffline = NSNumber(bool: true)
                    }
                }
            }
        }
    }
    
    private func deleteVisualization() {
        if let itemToDelete = itemToDelete {
            deleteVisualization(atIndex: itemToDelete);
        } else if let visualisation = selectedVisualization {
            if !APIManager.sharedInstance.reachability.isReachable() {
                OfflineManager.sharedManager.visualizationDeleted(visualisation.number)
            }
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(visualisation)
        }
        resetVisualizationCell()
        didChangeImage = false
    }
    
    private func deleteVisualization(atIndex index:Int) {
        if let visualization = Visualization.visualizationWithNumber(index) {
            itemToDelete = nil
            if !APIManager.sharedInstance.reachability.isReachable() {
                OfflineManager.sharedManager.visualizationDeleted(visualization.number)
            }
            CoreDataManager.sharedInstance.managedObjectContext?.deleteObject(visualization)
            if visualization == selectedVisualization {
                resetVisualizationCell()
                 didChangeImage = false
            }
        }
    }

    private func resetVisualizationCell() {
        messageSwitchView.receiveTime = .AnyTime
        visualisationView.configureWithText("", image: nil, number: NSNumber(integer: messageSwitchView.selectedSlot! + 1))
        selectedVisualization = nil
    }
    
    private func showVisualizationInPreview() {
        if let image = visualisationView.image {
            let text = visualisationView.text
            let scaledFontSize = Visualization.scaledFontSizeForFontSize(visualisationView.currentFontSize, imageSize: image.size, insideRect: visualisationView.imageView.bounds)
            let imagePreviewController = TextImagePreviewController.imagePreviewControllerWithImage(image)
			imagePreviewController.attributedText = NSAttributedString(string: text, attributes: Visualization.outlinedTextAttributesWithFontSize(scaledFontSize))
            imagePreviewController.delegate = self
            self.presentViewController(imagePreviewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func visualizationImageViewTap(sender: UITapGestureRecognizer) {
        showVisualizationInPreview()
    }


	// MARK: - NSFetchedResultsControllerDelegate

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		if let visualization = anObject as? Visualization {
			switch type {
			case .Insert:
				selectedVisualization = visualization
				messageSwitchView.reloadSlotAtIndex(visualization.number.integerValue)
				if TutorialManager.sharedInstance.completed {
					APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
				}
			case .Update:
				if TutorialManager.sharedInstance.completed {
					APIManager.sharedInstance.saveVisualization(visualization, handler: nil)
				}
			case .Delete:
				messageSwitchView.reloadSlotAtIndex(visualization.number.integerValue)
				messageSwitchView.selectedSlot = visualization.number.integerValue
                APIManager.sharedInstance.deleteVisualizationWithNumber(visualization.number, handler: nil)
			default:
				break
			}
		}
	}
}

// MARK: - TextImagePreviewControllerDelegate

extension VisualizationsViewController: TextImagePreviewControllerDelegate {
    func textImagePreviewControllerWillDismiss() {
        if !TutorialManager.sharedInstance.completed {
            TutorialManager.sharedInstance.nextStep()
        }
    }
}

// MARK: - MessageSwitchViewDelegate

extension VisualizationsViewController: MessageSwitchViewDelegate {

    func numberOfSlotsInMessageSwitchView(view: MessageSwitchView) -> Int {
        return Constants.NumberOfVisualizations
    }

    func messageSwitchView(view: MessageSwitchView, didSelectSlotAtIndex index: Int) {
        fillVisualisationWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchView(view: MessageSwitchView, isSlotEmptyAtIndex index: Int) -> Bool {
        return visualizationWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchView(view: MessageSwitchView, didSelectReceiveTime receiveTime: ReceiveTime) { }
    
    func messageSwitchView(view: MessageSwitchView, shouldSelectSlotAtIndex index: Int) -> Bool {
        if UpgradeManager.sharedInstance.isProVersion() {
            return true
        }
        if index < Constants.NumberOfFreeVisualizations  {
            return true
        } else {
            if TutorialManager.sharedInstance.completed {
                showUpgradeAppMessage()
            }
            return false
        }
    }
    
    func shouldActivateReceivingTimeViewInMessageSwitchView(view: MessageSwitchView) -> Bool {
        return true
    }
    
    func didFinishPickingReceivingTimeInMessageSwitchView(view: MessageSwitchView) {
        if messageSwitchView.receiveTime != ReceiveTime.AnyTime {
            if var visualizations = visualizationsWithReceiveTime(messageSwitchView.receiveTime) {
                if let selectedVis = selectedVisualization where visualizations.contains(selectedVis) {
                    visualizations.removeAtIndex(visualizations.indexOf(selectedVisualization!)!)
                }

                if visualizations.count > 0 {
                    showReceiveTimeDuplicationWarning()
                    resetSelectedSlot()
                } else {
                    saveChanges()
                }
            }
        } else {
            saveChanges()
        }
    }
    
    func showReceiveTimeDuplicationWarning() {
        tutorialViewController?.showMessage(ReceiveTimeConfirmationQuestion(messageSwitchView.receiveTime), upgrade: false)
        if TutorialManager.sharedInstance.completed {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(Affirmation.TextLimitShowDuration) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.tutorialViewController?.hideTutorialAnimated(true)
            }
        }
    }
    
    func resetSelectedSlot() {
        if let selectedVis = selectedVisualization {
            fillVisualisationWithNumber(selectedVis.number)
        } else {
            messageSwitchView.receiveTime = .AnyTime
        }
    }

    private func saveChanges() {
        if selectedVisualization == nil {
            saveVisualization()
        } else if let visualization = selectedVisualization where visualization.receiveTime != messageSwitchView.receiveTime {
            visualization.receiveTime = messageSwitchView.receiveTime
        }
    }
    
    func messageSwitchView(view: MessageSwitchView, longPressAtItem index: Int) {
        deleteVisualizationAtindex(index)
    }
    
    func messageSwitchView(view: MessageSwitchView, itemAvailable index: Int) -> Bool {
        return index < Constants.NumberOfFreeVisualizations ? true : false
    }
}

// MARK: - VisualizationViewDelegate

extension VisualizationsViewController: VisualizationViewDelegate {
        
    func visualizationViewDidTakePhoto(cell: VisualisationView) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            let authStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            if authStatus == .Authorized || authStatus == .NotDetermined {
                self?.presentImagePickerControllerWithSourceType(UIImagePickerControllerSourceType.Camera)
            } else {
                self?.presentViewController(AlertsController.cameraSettingsAlertController(), animated: true, completion: nil)
            }
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
    
    func deleteVisualizationAtindex(index: Int) {
        itemToDelete = index
        if let visual = Visualization.visualizationWithNumber(index) {
            if (visual.picture != nil) {
                tutorialViewController?.askConfirmationQuestion(DeleteConfirmationQuestion)
            }
        }
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            visualisationView.configureWithText(selectedVisualization?.text ?? "", image: image.upOrientedImage.fullScreenImage, number: NSNumber(integer: messageSwitchView.selectedSlot! + 1))
            didChangeImage = true
            tutorialViewController?.dismissViewControllerAnimated(true) { [weak self] in
                self?.visualisationView.mode = VisualizationViewMode.Editing
            }
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
