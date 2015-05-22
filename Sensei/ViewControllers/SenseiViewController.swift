//
//  SenseiViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import AdSupport

class SenseiViewController: BaseViewController {
    
    private struct Constants {
        static let CellReuseIdentifier = "SpeechBubbleCollectionViewCell"
        static let CellNibName = "SpeechBubbleCollectionViewCell"
        static let MinOpacity = CGFloat(0.2)
        static let DefaultCellHeight = CGFloat(30.0)
        static let DefaultSenseiBottomSpace = CGFloat(91)
        static let DefaultCollectionViewBottomSpace = CGFloat(48)
        static let DefaultCollectionViewContentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        static let DefaultAnimationDuration = 0.25
        static let ToAffirmationSegueIdentifier = "ToAffirmation"
        static let ToVizualizationSegueIdentifier = "ToVisualization"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var senseiBottomSpaceConstraint: NSLayoutConstraint!
    
    lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(Constants.CellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    var maxContentOffset: CGPoint {
        return CGPoint(x: 0, y: collectionView.contentSize.height - CGRectGetHeight(collectionView.frame) + collectionView.contentInset.bottom)
    }
    
    var dataSource = [Message]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as? AnswerableView)?.delegate = self
        
        collectionView.registerNib(UINib(nibName: Constants.CellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.CellReuseIdentifier)
        collectionView.contentInset = Constants.DefaultCollectionViewContentInset
        
        requestMessages()
        addKeyboardObservers()
        login()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllExeptLessons()
    }
    
    //MARK: - Logic
    
    private func requestMessages() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            let message0 = Lesson(text: "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.")
            let message1 = Lesson(text: "Alle warten auf das Licht\nFürchtet euch fürchtet euch nicht\nDie Sonne scheint mir aus den Augen\nsie wird heut Nacht nicht untergehen\nund die Welt zählt laut bis zehn")
            let message2 = Lesson(text: "eins\nHier kommt die Sonne\nzwei\n Hier kommt die Sonne \ndrei\nSie ist der hellste Stern von allen\nvier\nHier kommt die Sonne")
            let message3 = Lesson(text: "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.")
            let message4 = Lesson(text: "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.")
            let message5 = Lesson(text: "Alle warten auf das Licht. Fürchtet euch fürchtet euch nicht. Die Sonne scheint mir aus den Augen. sie wird heut Nacht nicht untergehen. und die Welt zählt laut bis zehn")
            let message6 = Lesson(text: "Eins, zwei, drei, vier, fünf, sechs, sieben, acht, neun, aus.")
            let message7 = Lesson(text: "eins\nHier kommt die Sonne\nzwei\n Hier kommt die Sonne \ndrei\nSie ist der hellste Stern von allen\nvier\nHier kommt die Sonne")
            self.addMessages([message0, message1, message2, message3, message4, message5, message6, message7], scroll: true) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.askQuestion(Question())
                }
            }
        }
    }
    
    private func askQuestion(var question: Question) {
        question.text = "What is your favorite division?"
//        question.answerType = AnswerType.Choice(options: ["Das Reich", "Totenkopf"])
        addMessages([question], scroll: false) {
            (self.view as? AnswerableView)?.askQuestion(question)
        }
    }
    
    private func addMessages(messages: [Message], scroll: Bool, completion: (() -> Void)?) {
        var indexPathes = [NSIndexPath]()
        for index in dataSource.count..<(dataSource.count + messages.count) {
            indexPathes.append(NSIndexPath(forItem: index, inSection: 0))
        }
        
        dataSource += messages
        
        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.insertItemsAtIndexPaths(indexPathes)
        }, completion: { (finished) -> Void in
            if scroll {
                self.collectionView.setContentOffset(self.maxContentOffset, animated: true)
            }
            if let completion = completion {
                completion()
            }
        })
    }
    
    private func deleteMessageAtIndexPath(indexPath: NSIndexPath) {
        dataSource.removeAtIndex(indexPath.item)

        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
        }, completion: { (finished) -> Void in
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.fadeCells()
        })
    }
    
    func removeAllExeptLessons() {
        dataSource = dataSource.filter { $0 is Lesson }
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        fadeCells()
    }
    
    func login() {
        let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
        let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
        println("IDFA = \(idfa)")
        println("timezone = \(currentTimeZone)")
    }
    
    //MARK: - UI
    
    private func fadeCells() {
        var cells = collectionView.visibleCells() as! [UICollectionViewCell]
        if cells.count == 0 {
            return
        }
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let height = CGRectGetHeight(collectionView.bounds) - layout.sectionInset.bottom
        let maxY = CGRectGetMaxY(collectionView.bounds) - layout.sectionInset.bottom - collectionView.contentInset.bottom
        
        for (_, cell) in enumerate(cells) {
            let opacity = 1 - ((maxY - CGRectGetMaxY(cell.frame)) / height)
            cell.alpha = max(opacity, Constants.MinOpacity)
        }
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if size.height > senseiBottomSpaceConstraint.constant {
            var contentInset = UIEdgeInsetsZero
            contentInset.bottom = size.height - Constants.DefaultCollectionViewBottomSpace
            view.layoutIfNeeded()
            self.collectionView.contentInset = contentInset
            UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
                self.senseiBottomSpaceConstraint.constant = size.height
                self.collectionView.contentOffset = self.maxContentOffset
                self.fadeCells()
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        view.layoutIfNeeded()
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { () -> Void in
            self.senseiBottomSpaceConstraint.constant = Constants.DefaultSenseiBottomSpace
            self.collectionView.contentInset = Constants.DefaultCollectionViewContentInset
            self.fadeCells()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier, destinationViewController = segue.destinationViewController as? UserMessageViewController {
            switch identifier {
                case Constants.ToAffirmationSegueIdentifier:
                    destinationViewController.userMessageType = UserMessageType.Affirmation
                case Constants.ToVizualizationSegueIdentifier:
                    destinationViewController.userMessageType = UserMessageType.Visualization
                default:
                    break
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension SenseiViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CellReuseIdentifier, forIndexPath: indexPath) as! SpeechBubbleCollectionViewCell
        cell.delegate = self
        let message = dataSource[indexPath.item]
        cell.titleLabel.text = message.text
        cell.type = message is Answer ? SpeechBubbleCollectionViewCellType.Me : SpeechBubbleCollectionViewCellType.Sensei
        return cell;
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SenseiViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        sizingCell.titleLabel.text = dataSource[indexPath.item].text
        sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: CGRectGetWidth(collectionView.bounds), height: Constants.DefaultCellHeight)
        return sizingCell.systemLayoutSizeFittingSize(CGSize(width: CGRectGetWidth(collectionView.bounds), height: CGFloat.max), withHorizontalFittingPriority: 1000, verticalFittingPriority: 50)
    }
}

// MARK: - UIScrollViewDelegate

extension SenseiViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        fadeCells()
    }
}

// MARK: - AnswerableViewDelegate

extension SenseiViewController: AnswerableViewDelegate {
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: String) {
        addMessages([Answer(answer: answer)], scroll: true) {
            self.requestMessages()
        }
        println("\(self) submitted answer: \(answer)")
    }
    
    func answerableViewDidCancel(answerableView: AnswerableView) {
        println("\(self) canceled question")
    }
}

// MARK: - SpeechBubbleCollectionViewCellDelegate

extension SenseiViewController: SpeechBubbleCollectionViewCellDelegate {
    
    func speechBubbleCollectionViewCellDidClose(cell: SpeechBubbleCollectionViewCell) {
        if let indexPath = collectionView.indexPathForCell(cell) {
            deleteMessageAtIndexPath(indexPath)
        }
    }
}
