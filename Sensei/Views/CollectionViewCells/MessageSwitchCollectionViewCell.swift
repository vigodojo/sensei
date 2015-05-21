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
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectMessageAtIndex index: Int)
    func messageSwitchCollectionViewCell(cell: MessageSwitchCollectionViewCell, didSelectReceiveTime receiveTime: ReceiveTime)
}

class MessageSwitchCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let SlotCellReuseIdentifier = "SlotCollectionViewCell"
        static let SwitchCellReuseIdentifier = "SwitchTableViewCell"
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
    var messageNumber = 6
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    @IBAction func save() {
        delegate?.messageSwitchCollectionViewCellDidSave(self)
    }
}

// MARK: - UICollectionViewDataSource

extension MessageSwitchCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messageNumber
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.SlotCellReuseIdentifier, forIndexPath: indexPath) as! SlotCollectionViewCell
        cell.titleLabel.text = "\(indexPath.item + 1)"
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessageSwitchCollectionViewCell: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.messageSwitchCollectionViewCell(self, didSelectMessageAtIndex: indexPath.item)
    }
}

// MARK: - UITableViewDataSource

extension MessageSwitchCollectionViewCell: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return switchItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SwitchCellReuseIdentifier, forIndexPath: indexPath) as! SwitchTableViewCell
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
