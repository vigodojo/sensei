//
//  TutorialBubbleCollectionViewCell.swift
//  Sensei
//
//  Created by Sauron Black on 7/16/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol TutorialBubbleCollectionViewCellDelegate: class {
    
    func tutorialBubbleCollectionViewCellDidYes(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNo(cell: TutorialBubbleCollectionViewCell)
    func tutorialBubbleCollectionViewCellDidNext(cell: TutorialBubbleCollectionViewCell)
}

class TutorialBubbleCollectionViewCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "TutorialBubbleCollectionViewCell"
    
    struct Notifications {
        static let NoAnswer = "TutorialBubbleCollectionViewCellNotificationsNoAnswer"
        static let YesAnswer = "TutorialBubbleCollectionViewCellNotificationsYesAnswer"
    }

    @IBOutlet weak var speechBubbleView: SpeechBubbleView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var controllsContainer: UIView!
    @IBOutlet weak var nextButton: UIButton!
    
    private let stringSeparator = StringColumnSeparator(font: UIFont.speechBubbleTextFont, columnSize: CGSizeZero)
    private var messages = [String]()
    
    weak var delegate: TutorialBubbleCollectionViewCellDelegate?
    
    var type = BubbleCollectionViewCellType.Sensei {
        didSet {
            switch type {
                case .Sensei:
                    controllsContainer.hidden = true
                    nextButton.hidden = false
                case .Confirmation:
                    controllsContainer.hidden = false
                    nextButton.hidden = true
                default:
                    break
            }
        }
    }
    
    var text: String {
        get {
            return join("", messages)
        }
        set {
            updateDataSource(newValue)
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let nib = UINib(nibName: TextCollectionViewCell.ReuseIdentifier, bundle: nil)
        collectionView.registerNib(nib, forCellWithReuseIdentifier: TextCollectionViewCell.ReuseIdentifier)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize.width = CGRectGetWidth(collectionView.frame)
        collectionView.collectionViewLayout.invalidateLayout()
        let aText = text
        if !aText.isEmpty {
            updateDataSource(aText)
        }
    }
    
    // MARK: - Private
    
    private func updateDataSource(text: String) {
        stringSeparator.columnSize = collectionView.frame.size
        messages = stringSeparator.separateString(text)
        collectionView.reloadData()
        if messages.count > 0 {
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: .None, animated: false)
        }
    }

    // MARK: - IBActions
    
    @IBAction func yesAnswer() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.YesAnswer, object: nil)
        delegate?.tutorialBubbleCollectionViewCellDidYes(self)
    }
    
    @IBAction func noAnswer() {
        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.NoAnswer, object: nil)
        delegate?.tutorialBubbleCollectionViewCellDidNo(self)
    }
    
    @IBAction func next() {
        if let indexPath = collectionView.indexPathsForVisibleItems().first as? NSIndexPath {
            if indexPath.item >= messages.count - 1 {
                delegate?.tutorialBubbleCollectionViewCellDidNext(self)
            } else {
                let newIndexPath = NSIndexPath(forItem: indexPath.item + 1, inSection: 0)
                collectionView.scrollToItemAtIndexPath(newIndexPath, atScrollPosition: .None, animated: true)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension TutorialBubbleCollectionViewCell: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TextCollectionViewCell.ReuseIdentifier, forIndexPath: indexPath) as! TextCollectionViewCell
        cell.text = messages[indexPath.item]
        return cell
    }
}
