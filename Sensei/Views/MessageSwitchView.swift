//
//  MessageSwitchCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 5/21/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol MessageSwitchViewDelegate: class {
    
    func numberOfSlotsInMessageSwitchView(view: MessageSwitchView) -> Int
    func messageSwitchView(view: MessageSwitchView, didSelectSlotAtIndex index: Int)
    func messageSwitchView(view: MessageSwitchView, isSlotEmptyAtIndex index: Int) -> Bool
    func messageSwitchView(view: MessageSwitchView, didSelectReceiveTime receiveTime: ReceiveTime)
}

@IBDesignable
class MessageSwitchView: UIView {
    
    private struct Constants {
        static let NibName = "MessageSwitchView"
        static let SlotCellNibName = "SlotCollectionViewCell"
        static let EmtySlotTextColor = UIColor(hexColor: 0xEA212D)
        static let FilledSlotTextColor = UIColor.blackColor()
    }
    
    @IBOutlet weak var slotsCollectionView: UICollectionView!
    @IBOutlet weak var receiveTimeTextView: UITextView!
    
    private lazy var receiveTimePickerInputAccessoryView: PickerInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = PickerInputAccessoryView(frame: rect)
        inputAccessoryView.rightButton.setTitle("Done", forState: UIControlState.Normal)
        inputAccessoryView.leftButton.hidden = true
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            self?.receiveTimeTextView.resignFirstResponder()
        }
        return inputAccessoryView
    }()
    
    private lazy var receiveTimePickerView: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    weak var delegate: MessageSwitchViewDelegate?
    
    let switchItems = [ReceiveTime.Morning, ReceiveTime.AnyTime, ReceiveTime.Evening]
    
    var reseiveTime: ReceiveTime {
        get {
            let index = receiveTimePickerView.selectedRowInComponent(0)
            return index == -1 ? ReceiveTime.Morning: switchItems[index]
        }
        set {
            if let index = find(switchItems, newValue) {
                receiveTimeTextView.text = "\(newValue)"
                receiveTimePickerView.selectRow(index, inComponent: 0, animated: false)
            }
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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    // MARK: - Private
    
    private func setup() {
        if let view = NSBundle.mainBundle().loadNibNamed(Constants.NibName, owner: self, options: nil).first as? UIView {
            addEdgePinnedSubview(view)
        }
        slotsCollectionView.registerNib(UINib(nibName: Constants.SlotCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.SlotCellNibName)
        receiveTimeTextView.inputView = receiveTimePickerView
        receiveTimeTextView.inputAccessoryView = receiveTimePickerInputAccessoryView
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

extension MessageSwitchView: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return delegate?.numberOfSlotsInMessageSwitchView(self) ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SlotCellNibName, forIndexPath: indexPath) as! SlotCollectionViewCell
        cell.titleLabel.text = "\(indexPath.item + 1)"
        let isEmpty = delegate?.messageSwitchView(self, isSlotEmptyAtIndex: indexPath.item) ?? true
        cell.titleLabel.textColor = isEmpty ? Constants.EmtySlotTextColor: Constants.FilledSlotTextColor
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessageSwitchView: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.messageSwitchView(self, didSelectSlotAtIndex: indexPath.item)
    }
}

// MARK: - UIPickerViewDataSource

extension MessageSwitchView: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return switchItems.count
    }
}

// MARK: - UIPickerViewDelegate

extension MessageSwitchView: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "\(switchItems[row])"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        receiveTimeTextView.text = "\(switchItems[row])"
        delegate?.messageSwitchView(self, didSelectReceiveTime: switchItems[row])
    }
}
