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
    func messageSwitchView(view: MessageSwitchView, shouldSelectSlotAtIndex index: Int) -> Bool
    func shouldActivateReceivingTimeViewInMessageSwitchView(view: MessageSwitchView) -> Bool
    func didFinishPickingReceivingTimeInMessageSwitchView(view: MessageSwitchView)
}

let MessageSwitchViewSclotsCollectionViewBoundsContext = UnsafeMutablePointer<Void>()

class MessageSwitchView: UIView {
    
    private struct Constants {
        static let NibName = "MessageSwitchView"
        static let SlotCellNibName = "SlotCollectionViewCell"
        static let EmtySlotTextColor = UIColor(hexColor: 0xEA212D)
        static let FilledSlotTextColor = UIColor.blackColor()
    }
    
    @IBOutlet weak var slotsCollectionView: UICollectionView!
    @IBOutlet weak var receiveTimeTextView: UITextView!
    @IBOutlet weak var receiveTimeButton: UIButton!
    
    private lazy var receiveTimePickerInputAccessoryView: PickerInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = PickerInputAccessoryView(frame: rect)
        inputAccessoryView.rightButton.setTitle("Done", forState: UIControlState.Normal)
        inputAccessoryView.leftButton.hidden = true
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            self?.receiveTimeTextView.resignFirstResponder()
            if let weakSelf = self {
                weakSelf.delegate?.didFinishPickingReceivingTimeInMessageSwitchView(weakSelf)
            }
        }
        return inputAccessoryView
    }()
    
    private lazy var receiveTimePickerView: UIPickerView = { [unowned self] in
        let picker = UIPickerView(frame: CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.frame), height: 250)))
        picker.dataSource = self
        picker.delegate = self
		picker.backgroundColor = UIColor.whiteColor()
        return picker
    }()
    
    private var currentSelectedIndexPath: NSIndexPath?
    
    weak var delegate: MessageSwitchViewDelegate? {
        didSet {
            calculateSlotItemWidth()
        }
    }
    
    let switchItems = [ReceiveTime.Morning, ReceiveTime.AnyTime, ReceiveTime.Evening]
    
    var receiveTime: ReceiveTime {
        get {
            let index = receiveTimePickerView.selectedRowInComponent(0)
            return index == -1 ? ReceiveTime.Morning: switchItems[index]
        }
        set {
            if let index = switchItems.indexOf(newValue) {
                receiveTimeTextView.text = "\(newValue)"
                receiveTimePickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
    }
    
    var selectedSlot: Int? {
        get {
            return slotsCollectionView.indexPathsForSelectedItems()?.first?.item
        }
        set {
            if let index = newValue {
                if let previousSelectedIndxPath = currentSelectedIndexPath {
                    if previousSelectedIndxPath.item != index {
                        slotsCollectionView.deselectItemAtIndexPath(previousSelectedIndxPath, animated: false)
                    } else {
                        return
                    }
                }
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                slotsCollectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
                currentSelectedIndexPath = indexPath
            }
        }
    }
    
    // MARK: - Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    deinit {
        slotsCollectionView.removeObserver(self, forKeyPath: "bounds", context: MessageSwitchViewSclotsCollectionViewBoundsContext)
    }
    
    // MARK: - Private
    
    private func setup() {
        if let view = NSBundle.mainBundle().loadNibNamed(Constants.NibName, owner: self, options: nil).first as? UIView {
            addEdgePinnedSubview(view)
        }
        slotsCollectionView.addObserver(self, forKeyPath: "bounds", options: NSKeyValueObservingOptions.New, context: MessageSwitchViewSclotsCollectionViewBoundsContext)
        slotsCollectionView.registerNib(UINib(nibName: Constants.SlotCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.SlotCellNibName)
        slotsCollectionView.allowsMultipleSelection = true
        receiveTimeTextView.inputView = receiveTimePickerView
        receiveTimeTextView.inputAccessoryView = receiveTimePickerInputAccessoryView
        calculateSlotItemWidth()
    }

    // MARK: - Public
    
    func reloadSlots() {
        slotsCollectionView.reloadData()
    }
    
    func reloadSlotAtIndex(index: Int) {
        slotsCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }
    
    // MARK: - Private
    
    private func calculateSlotItemWidth() {
        if let delegate = delegate {
            let numberOfItems = delegate.numberOfSlotsInMessageSwitchView(self)
            let defaultItemWidth = (slotsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width
            let itemsWidth = CGRectGetWidth(slotsCollectionView.frame) / CGFloat(numberOfItems)
            (slotsCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width = max(defaultItemWidth, itemsWidth)
        }
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == MessageSwitchViewSclotsCollectionViewBoundsContext {
            calculateSlotItemWidth()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func activateReceivingTimeView() {
        if let delegate = delegate where delegate.shouldActivateReceivingTimeViewInMessageSwitchView(self) {
            receiveTimeTextView.becomeFirstResponder()
        }
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
        if currentSelectedIndexPath == indexPath {
            cell.selected = true
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessageSwitchView: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let previousSelectedIndxPath = currentSelectedIndexPath {
            collectionView.deselectItemAtIndexPath(previousSelectedIndxPath, animated: false)
        }
        currentSelectedIndexPath = indexPath
        delegate?.messageSwitchView(self, didSelectSlotAtIndex: indexPath.item)
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let previousSelectedIndxPath = currentSelectedIndexPath {
            return previousSelectedIndxPath != indexPath
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let delegate = delegate {
            return delegate.messageSwitchView(self, shouldSelectSlotAtIndex: indexPath.item)
        }
        return true
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
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(switchItems[row])"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        receiveTimeTextView.text = "\(switchItems[row])"
        delegate?.messageSwitchView(self, didSelectReceiveTime: switchItems[row])
    }
}
