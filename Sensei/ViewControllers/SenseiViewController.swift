//
//  SenseiViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SenseiViewController: UIViewController {
    
    private struct Constants {
        static let CellReuseIdentifier = "SpeechBubbleCollectionViewCell"
        static let CellNibName = "SpeechBubbleCollectionViewCell"
        static let MinOpacity = CGFloat(0.2)
        static let DefaultCellHeight = CGFloat(30.0)
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var answerTextField: UITextField = {
       UITextField(frame: CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), 44))
    }()
    
    lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(Constants.CellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    var dataSource = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.registerNib(UINib(nibName: Constants.CellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.CellReuseIdentifier)
        requestMessages()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? {
        return answerTextField
    }
    
    private func requestMessages() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            let message0 = Message(); message0.text = "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus."
            let message1 = Message(); message1.text = "Alle warten auf das Licht\nFürchtet euch fürchtet euch nicht\nDie Sonne scheint mir aus den Augen\nsie wird heut Nacht nicht untergehen\nund die Welt zählt laut bis zehn"
            let message2 = Message(); message2.text = "eins\nHier kommt die Sonne\nzwei\n Hier kommt die Sonne \ndrei\nSie ist der hellste Stern von allen\nvier\nHier kommt die Sonne"
            let message3 = Message(); message3.text = "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus."
            let message4 = Message(); message4.text = "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus."
            let message5 = Message(); message5.text = "Alle warten auf das Licht. Fürchtet euch fürchtet euch nicht. Die Sonne scheint mir aus den Augen. sie wird heut Nacht nicht untergehen. und die Welt zählt laut bis zehn"
            let message6 = Message(); message6.text = "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus."
            let message7 = Message(); message7.text = "eins\nHier kommt die Sonne\nzwei\n Hier kommt die Sonne \ndrei\nSie ist der hellste Stern von allen\nvier\nHier kommt die Sonne"
            self.didLoadMessages([message0, message1, message2, message3, message4, message5, message6, message7])
        }
    }
    
    private func didLoadMessages(newMessages: [Message]) {
        dataSource += newMessages
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.contentOffset = CGPoint(x: 0, y: collectionView.contentSize.height - CGRectGetHeight(collectionView.frame))
        collectionView.layoutIfNeeded()
        fadeCells(collectionView.visibleCells() as! [UICollectionViewCell])
        view.becomeFirstResponder()
//        becomeFirstResponder()
    }
    
    func fadeCells(cells: [UICollectionViewCell]) {
        if cells.count == 0 {
            return
        }
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let height = CGRectGetHeight(collectionView.bounds) - layout.sectionInset.bottom
        let maxY = CGRectGetMaxY(collectionView.bounds) - layout.sectionInset.bottom
        
        for (_, cell) in enumerate(cells) {
            let opacity = 1 - ((maxY - CGRectGetMaxY(cell.frame)) / height)
            cell.alpha = max(opacity, Constants.MinOpacity)
            cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        }
    }
}

extension SenseiViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! SpeechBubbleCollectionViewCell
        cell.titleLabel.text = dataSource[indexPath.item].text
        return cell;
    }
}

extension SenseiViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        sizingCell.titleLabel.text = dataSource[indexPath.item].text
        sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(collectionView.bounds), height: Constants.DefaultCellHeight)
        return sizingCell.systemLayoutSizeFittingSize(CGSize(width: CGRectGetWidth(collectionView.bounds), height: CGFloat.max), withHorizontalFittingPriority: 1000, verticalFittingPriority: 50)
    }
}

extension SenseiViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var visibleCells = collectionView.visibleCells() as! [UICollectionViewCell]
        fadeCells(visibleCells)
    }
}
