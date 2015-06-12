//
//  MessageSwitchCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol MessageSwitchCollectionViewCellDelegate: class {
    
    func messageSwitchCollectionViewCellDidSave(cell: MessageSwitchCollectionViewCell)
    func numberOfSlotsInMessageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell) -> Int
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectSlotAtIndex index: Int)
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, isSlotEmptyAtIndex index: Int) -> Bool
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime)
}

class MessageSwitchCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let SlotCellNibName = "SlotCollectionViewCell"
        static let EmtySlotTextColor = UIColor(hexColor: 0xEA212D)
        static let FilledSlotTextColor = UIColor.blackColor()
    }
    
    @IBOutlet weak var slotsCollectionView: UICollectionView!
    @IBOutlet weak var messageTimingTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    private lazy var receiveTimePickerView: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    weak var delegate: MessageSwitchCollectionViewCellDelegate?
    
    var saveButtonHidden: Bool {
        get {
            return saveButton.hidden
        }
        set {
            saveButton.hidden = newValue
        }
    }
    
    let switchItems = [ReceiveTime.Morning, ReceiveTime.AnyTime, ReceiveTime.Evening]
    
    var reseiveTime: ReceiveTime? {
        get {

            return nil
        }
        set {
            
        }
    }
    
    var selectedSlot: Int? {
        get {
            return slotsCollectionView.indexPathsForSelectedItems().first?.item
        }
        set {
            if let index = newValue {
                slotsCollectionView.selectItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        slotsCollectionView.registerNib(UINib(nibName: Constants.SlotCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.SlotCellNibName)
        messageTimingTextField.inputView = receiveTimePickerView
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    // MARK: - IBActions
    
    @IBAction func save() {
        delegate?.messageSwitchCollectionViewCellDidSave(self)
    }
    
    // MARK: - Public
    
    func reloadSlots() {
        slotsCollectionView.reloadData()
    }
    
    func reloadSlotAtIndex(index: Int) {
        slotsCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }
}

// MARK: - UICollectionViewDataSource

extension MessageSwitchCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return delegate?.numberOfSlotsInMessageSwitchCollectionViewCell(self) ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SlotCellNibName, forIndexPath: indexPath) as! SlotCollectionViewCell
        cell.titleLabel.text = "\(indexPath.item + 1)"
        let isEmpty = delegate?.messageSwitchCollectionViewCell(self, isSlotEmptyAtIndex: indexPath.item) ?? true
        cell.titleLabel.textColor = isEmpty ? Constants.EmtySlotTextColor: Constants.FilledSlotTextColor
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessageSwitchCollectionViewCell: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.messageSwitchCollectionViewCell(self, didSelectSlotAtIndex: indexPath.item)
    }
}

// MARK: - UIPickerViewDataSource

extension MessageSwitchCollectionViewCell: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return switchItems.count
    }
}

// MARK: - UIPickerViewDelegate

extension MessageSwitchCollectionViewCell: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "\(switchItems[row])"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
}
