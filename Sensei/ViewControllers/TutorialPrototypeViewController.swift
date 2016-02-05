//
//  ViewController.swift
//  smth
//
//  Created by Sergey Sheba on 2/3/16.
//  Copyright © 2016 sergeysheba. All rights reserved.
//

import UIKit

class TutorialPrototypeViewController: UIViewController {

    @IBOutlet weak var nextBurron: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var nextTimer: NSTimer?
    var canChangeStep: Bool = true
    var numberOfItems: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextBurron.enabled = false
        prevButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    // MARK: IBAction
    @IBAction func goBackward(sender: AnyObject) {
        if nextTimer == nil && canChangeStep {
            showPrev()
        }
    }
    
    @IBAction func goForward(sender: AnyObject) {
        if nextTimer == nil && canChangeStep {
            showNext()
        }
    }
    
    @IBAction func addStepAction(sender: AnyObject) {
        if canChangeStep {
            addStep()
        }
    }
    
    @IBAction func popViewController(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Private
    
    private func addStep() {
        canChangeStep = false
        numberOfItems++
        let indexPath = NSIndexPath(forItem: numberOfItems - 1, inSection: 0)
        
        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.insertItemsAtIndexPaths([indexPath])
        }, completion: { (finished) -> Void in
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
            self.canChangeStep = true
            
            self.prevButton.enabled = true;
            self.nextBurron.enabled = false
        })
    }
    
    private func showPrev() {
        if let currentIndexPath = collectionView.indexPathsForVisibleItems().first {
            if currentIndexPath.item - 1 < 0 {
                return
            }
            let indexPath = NSIndexPath(forItem: currentIndexPath.item-1, inSection: 0)
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
            self.prevButton.enabled = indexPath.item > 0;
            self.nextBurron.enabled = indexPath.item < numberOfItems - 1
        }
    }
    
    private func showNext() {
        if let currentIndexPath = collectionView.indexPathsForVisibleItems().first {
            if currentIndexPath.item + 1 >= numberOfItems {
                return
            }
            let indexPath = NSIndexPath(forItem: currentIndexPath.item + 1, inSection: 0)
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
            self.prevButton.enabled = indexPath.item > 0;
            self.nextBurron.enabled = indexPath.item < numberOfItems - 1
        }
    }
}

extension TutorialPrototypeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItems
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TextViewCell", forIndexPath: indexPath) as! TextViewCell
        cell.delegate = self
        cell.textView.text = "Item: \(indexPath.row + 1)\n\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
        
        dispatch_async(dispatch_get_main_queue(), {
            cell.textView.contentOffset = CGPointZero
        })
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
    }
}

extension TutorialPrototypeViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if let currentIndexPath = collectionView.indexPathsForVisibleItems().first {
            self.prevButton.enabled = currentIndexPath.item > 0;
            self.nextBurron.enabled = currentIndexPath.item < numberOfItems - 1
        }
    }
}

extension TutorialPrototypeViewController: TextViewCellDelegate {
    
    func textViewDidScrollToBottom() {
        if nextTimer == nil {
            nextTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "goToNextTimerAction:", userInfo: nil, repeats: false)
        }
    }
    
    func goToNextTimerAction(timer: NSTimer) {
        nextTimer = nil
        if let currentIndexPath = collectionView.indexPathsForVisibleItems().first where currentIndexPath.item + 1 >= numberOfItems {
            addStep()
        }
    }
}