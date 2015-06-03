//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData

enum UserMessageType: Printable {
    
    case Affirmation
    case Visualization
    
    var numberOfUserMessages: Int {
        switch self {
            case .Affirmation: return 6
            case .Visualization: return 5
        }
    }
    
    var description: String {
        switch self {
            case .Affirmation: return "AFFIRMATION"
            case .Visualization: return "VISUALIZATION"
        }
    }
}

class UserMessageViewController: SenseiNavigationController, UINavigationControllerDelegate {
    
    private struct Constants {
        static let MessageSwitchCellReuseIdentifier = "MessageSwitchCollectionViewCell"
        static let MessageSwitchCellHeight: CGFloat = 170
        static let AffirmationCellReuseIdentifier = "AffirmationCollectionViewCell"
        static let AffirmationCellHeight: CGFloat = 110
        static let VisuaizationCellReuseIdentifier = "VisualizationCollectionViewCell"
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "\(userMessageType)"
        }
    }
    
    private var messageSwitchCell: MessageSwitchCollectionViewCell?
    private var affirmationCell: AffirmationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectUserMessageWithNumber(NSNumber(integer:0))
            }
        }
    }
    private var visualizationCell: VisualizationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectUserMessageWithNumber(NSNumber(integer:0))
            }
        }
    }
    
    private lazy var userMessagesFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    var userMessageType = UserMessageType.Affirmation
    
    var entityName: String {
        switch userMessageType {
            case .Affirmation: return Affirmation.EntityName
            case .Visualization: return Visualization.EntityName
        }
    }
    
    override var tutorialOn: Bool {
        switch userMessageType {
            case .Affirmation: return true
            case .Visualization: return false
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupItems()
        fetchUserMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - SenseiNavigationController
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        if cell is MessageSwitchCollectionViewCell {
            messageSwitchCell = (cell as? MessageSwitchCollectionViewCell)
            messageSwitchCell?.delegate = self
        } else if cell is VisualizationCollectionViewCell {
            visualizationCell = (cell as? VisualizationCollectionViewCell)
            visualizationCell?.delegate = self
        } else if cell is AffirmationCollectionViewCell {
            affirmationCell = (cell as? AffirmationCollectionViewCell)
            affirmationCell?.delegate = self
        }
        return cell
    }
    
    // MARK: - Private
    
    private func setupItems() {
        items.append(Item(reuseIdentifier: Constants.MessageSwitchCellReuseIdentifier, height: Constants.MessageSwitchCellHeight))
        switch userMessageType {
            case UserMessageType.Affirmation:
                items.append(Item(reuseIdentifier: Constants.AffirmationCellReuseIdentifier, height: Constants.AffirmationCellHeight))
            case UserMessageType.Visualization:
                items.append(Item(reuseIdentifier: Constants.VisuaizationCellReuseIdentifier, height: remainingHeight))
                break
        }
    }
    
    private func fetchUserMessages() {
        var error: NSError? = nil
        if !userMessagesFetchedResultController.performFetch(&error) {
            println("Failed to fetch user messages with error: \(error)")
        }
    }
    
    private func selectUserMessageWithNumber(number: NSNumber) {
        messageSwitchCell?.selectedSlot = number.integerValue
        if let userMessage = userMessageWithNumber(number) {
            messageSwitchCell?.reseiveTime = userMessage.receiveTime
            switch userMessageType {
                case .Affirmation:
                    affirmationCell?.textView.text = userMessage.text
                case .Visualization:
                    visualizationCell?.textLabel.text = userMessage.text
                    visualizationCell?.imageView.image = (userMessage as! Visualization).picture
            }
        } else {
            messageSwitchCell?.reseiveTime = .Morning
            switch userMessageType {
            case .Affirmation:
                affirmationCell?.textView.text = ""
            case .Visualization:
                visualizationCell?.text = "ENTERED TEXT SUPER EMPOSED ON TOP OF IMAGE AT THE BOTTOM"
                visualizationCell?.imageView.image = nil
            }
        }
    }
    
    private func saveAffirmation() {
        let index = messageSwitchCell?.selectedSlot
        let receiveTime = messageSwitchCell?.reseiveTime
        let text = affirmationCell?.textView.text
        if let index = index, receiveTime = receiveTime, text = text {
            if let userMessage = userMessageWithNumber(index) {
                if text.isEmpty {
                    CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(userMessage)
                    CoreDataManager.sharedInstance.saveContext()
                } else if userMessage.text != text || userMessage.receiveTime != receiveTime {
                    userMessage.text = text
                    userMessage.receiveTime = receiveTime
                    CoreDataManager.sharedInstance.saveContext()
                }
            } else if !text.isEmpty {
                Affirmation.createAffirmationNumber(index, text: text, receiveTime: receiveTime)
                CoreDataManager.sharedInstance.saveContext()
            }
        }
    }
    
    private func hasChangesBeenMade() -> Bool {
        if let index = messageSwitchCell?.selectedSlot {
            let receiveTime = messageSwitchCell?.reseiveTime ?? ReceiveTime.Morning
            switch userMessageType {
                case .Affirmation:
                    let text = affirmationCell?.textView.text ?? ""
                    if let affirmation = userMessageWithNumber(index) as? Affirmation {
                        return hasAffirmationBeenChanged(affirmation, newText: text, newReceiveTime: receiveTime)
                    }
                    return !text.isEmpty
                case .Visualization:
                    let text = visualizationCell?.text ?? ""
                    let image = visualizationCell?.imageView?.image
                    if let visualization = userMessageWithNumber(index) as? Visualization {
                        return hasVisualizationBeenChanged(visualization, newText: text, newReceiveTime: receiveTime, newImage: image)
                    }
                    return !text.isEmpty || image != nil
            }
        }
        return false
    }
    
    private func hasAffirmationBeenChanged(affirmation: Affirmation, newText: String, newReceiveTime: ReceiveTime) -> Bool {
        return affirmation.text != newText || affirmation.receiveTime != newReceiveTime
    }
    
    private func hasVisualizationBeenChanged(visualization: Visualization, newText: String, newReceiveTime: ReceiveTime, newImage: UIImage?) -> Bool {
        return visualization.text != newText || visualization.receiveTime != newReceiveTime || visualization.picture != newImage
    }
    
    private func userMessageWithNumber(number: NSNumber) -> UserMessage? {
        if let fetchedObjects = userMessagesFetchedResultController.fetchedObjects as? [UserMessage] {
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
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        let offset = size.height - (CGRectGetHeight(collectionView.frame) - collectionView.contentSize.height)
        if  offset > 0 {
            collectionView.bounces = true
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
            UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
                self.collectionView.contentOffset = CGPoint(x: 0, y: offset)
            }, completion: nil)
        }
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        collectionView.bounces = false
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
            self.collectionView.contentInset = UIEdgeInsetsZero
        }, completion: nil)
    }
    
    // MARK: - IBAction
    
    @IBAction func visualizationImageViewTap(sender: UITapGestureRecognizer) {
        println("Tap Image")
    }
}

// MARK: - MessageSwitchCollectionViewCellDelegate

extension UserMessageViewController: MessageSwitchCollectionViewCellDelegate {
    
    func messageSwitchCollectionViewCellDidSave(cell: MessageSwitchCollectionViewCell) {
        switch userMessageType {
            case .Affirmation:
                saveAffirmation()
                affirmationCell?.textView.resignFirstResponder()
            case .Visualization:
                break;
        }
    }
    
    func numberOfSlotsInMessageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell) -> Int {
        return userMessageType.numberOfUserMessages
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectSlotAtIndex index: Int) {
        selectUserMessageWithNumber(NSNumber(integer: index))
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, isSlotEmptyAtIndex index: Int) -> Bool {
        return userMessageWithNumber(NSNumber(integer: index)) == nil
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        println("\(self) ReceiveTime \(receiveTime.rawValue)")
    }
}

// MARK: - AffirmationCollectionViewCellDelegate

extension UserMessageViewController: AffirmationCollectionViewCellDelegate {
    
    func affirmationCollectionViewCellDidChange(cell: AffirmationCollectionViewCell) {
        messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
    }
}

// MARK: - VisualizationCollectionViewCellDelegate

extension UserMessageViewController: VisualizationCollectionViewCellDelegate {
    
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
    
    func visualizationCollectionViewCellDidEdit(cell: VisualizationCollectionViewCell) {
        //
    }
}

// MARK: - UIImagePickerControllerDelegate

extension UserMessageViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            visualizationCell?.imageView.image = image
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension UserMessageViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let userMessage = anObject as? UserMessage {
            switch type {
                case .Insert:
                    messageSwitchCell?.reloadSlotAtIndex(userMessage.number.integerValue)
                    let number = ((userMessage.number.integerValue + 1) % userMessageType.numberOfUserMessages)
                    selectUserMessageWithNumber(number)
                    APIManager.sharedInstance.saveUserMessage(userMessage, handler: nil)
                case .Update:
                    let number = ((userMessage.number.integerValue + 1) % userMessageType.numberOfUserMessages)
                    selectUserMessageWithNumber(number)
                    APIManager.sharedInstance.saveUserMessage(userMessage, handler: nil)
                case .Delete:
                    messageSwitchCell?.reloadSlotAtIndex(userMessage.number.integerValue)
                    messageSwitchCell?.selectedSlot = userMessage.number.integerValue
                    APIManager.sharedInstance.deleteUserMessage(userMessage, handler: nil)
                default:
                    break
            }
            messageSwitchCell?.saveButtonHidden = !hasChangesBeenMade()
        }
    }
}
