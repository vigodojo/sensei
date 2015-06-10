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
        static let SwitchCellNibName = "SwitchTableViewCell"
        static let EmtySlotTextColor = UIColor(hexColor: 0xEA212D)
        static let FilledSlotTextColor = UIColor.blackColor()
    }
    
    @IBOutlet weak var slotsCollectionView: UICollectionView!
    @IBOutlet weak var switchTableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
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
            if let indexPath = switchTableView.indexPathForSelectedRow() {
                return switchItems[indexPath.item]
            }
            return nil
        }
        set {
            if let value = newValue, index = find(switchItems, value) {
                switchTableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        slotsCollectionView.registerNib(UINib(nibName: Constants.SlotCellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.SlotCellNibName)
        switchTableView.registerNib(UINib(nibName: Constants.SwitchCellNibName, bundle: nil), forCellReuseIdentifier: Constants.SwitchCellNibName)
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

// MARK: - UITableViewDataSource

extension MessageSwitchCollectionViewCell: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return switchItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SwitchCellNibName, forIndexPath: indexPath) as! SwitchTableViewCell
        cell.titleLabel.text = "\(switchItems[indexPath.row])"
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MessageSwitchCollectionViewCell: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.messageSwitchCollectionViewCell(self, didSelectReceiveTime: switchItems[indexPath.row])
    }
}
