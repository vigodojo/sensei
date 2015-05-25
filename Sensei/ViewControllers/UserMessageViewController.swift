//
//  UserMessgeViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

enum UserMessageType: Printable {
    
    case Affirmation
    case Visualization
    
    var description: String {
        switch self {
            case .Affirmation: return "Affirmation"
            case .Visualization: return "Visualization"
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
        static let NumberOfUserMessages = 6
    }
    
    override weak var navigationCell: NavigationCollectionViewCell? {
        didSet {
            navigationCell?.titleLabel.text = "\(userMessageType)"
        }
    }
    
    var messageSwitchCell: MessageSwitchCollectionViewCell?
    var affirmationCell: AffirmationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectUserMessageWithNumber(NSNumber(integer:1))
            }
        }
    }
    var visualizationCell: VisualizationCollectionViewCell? {
        didSet {
            if messageSwitchCell?.selectedSlot == nil {
                selectUserMessageWithNumber(NSNumber(integer:1))
            }
        }
    }
    
    var userMessageType = UserMessageType.Affirmation
    
    var userMessages = [UserMessage]()
    
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
        switch userMessageType {
            case .Affirmation: userMessages = Affirmation.affirmations
            case .Visualization: userMessages = Visualization.visualizations
        }
    }
    
    private func selectUserMessageWithNumber(number: NSNumber) {
        messageSwitchCell?.selectedSlot = number.integerValue - 1
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
                visualizationCell?.textLabel.text = ""
                visualizationCell?.imageView.image = nil
            }
        }
    }
    
    private func saveAffirmation() {
        let index = messageSwitchCell?.selectedSlot
        let receiveTime = messageSwitchCell?.reseiveTime
        let text = affirmationCell?.textView.text
        if let index = index, receiveTime = receiveTime, text = text where !text.isEmpty {
            if let userMessage = userMessageWithNumber(index + 1) {
                userMessage.text = text
                userMessage.receiveTime = receiveTime
            } else {
                userMessages.append(Affirmation.createAffirmationNumber(index + 1, text: text, receiveTime: receiveTime))
            }
        }
    }
    
    private func userMessageWithNumber(number: NSNumber) -> UserMessage? {
        let filteredMessages = userMessages.filter(){ $0.number.compare(number) == .OrderedSame }
        return filteredMessages.first
    }
    
    private func presentImagePickerControllerWithSourceType(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
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
            case .Visualization:
                break;
        }
        println("\(self) Save")
    }
    
    func numberOfSlotsInMessageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell) -> Int {
        return Constants.NumberOfUserMessages
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectSlotAtIndex index: Int) {
        selectUserMessageWithNumber(NSNumber(integer: index + 1))
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, isSlotEmptyAtIndex index: Int) -> Bool {
        return userMessageWithNumber(NSNumber(integer: index + 1)) == nil
    }
    
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime) {
        println("\(self) ReceiveTime \(receiveTime.rawValue)")
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
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            visualizationCell?.imageView.image = image
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
