//
//  SenseiViewController.swift
//  Sensei
//
//  Created by Sauron Black on 5/14/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import CoreData
import AdSupport

class SenseiViewController: BaseViewController {
    
    private struct Constants {
        static let CellReuseIdentifier = "SpeechBubbleCollectionViewCell"
        static let CellNibName = "SpeechBubbleCollectionViewCell"
        static let MinOpacity = CGFloat(0.2)
        static let DefaultCellHeight = CGFloat(30.0)
        static let DefaultBottomSpace = CGFloat(66.0)
        static let DefaultAnimationDuration = 0.25
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var senseiBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var senseiImageView: UIImageView!
    
    private lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(Constants.CellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    private var maxContentOffset: CGPoint {
        let y = collectionView.contentSize.height - CGRectGetHeight(collectionView.frame) + collectionView.contentInset.bottom + min(0, bottomContentInset)
        return CGPoint(x: 0, y: max(y, -collectionView.contentInset.top))
    }
    
    private var bottomContentInset: CGFloat {
        if dataSource.count > 0 {
            var index = dataSource.count - 1
            var height: CGFloat = 0
            while index > -1 && dataSource[index] is Answer {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                let cellSize = collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: indexPath)
                height += cellSize.height + (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
                index--
            }
            if index > -1 {
                let lastIndexPath = NSIndexPath(forItem: index, inSection: 0)
                let lastCellSize = collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: lastIndexPath)
                return CGRectGetHeight(senseiImageView.frame) - lastCellSize.height - height
            }
        }
        return 0
    }
    
    private var collectionViewBottomContentInset: CGFloat {
        return max(0, bottomContentInset)
    }
    
    private lazy var lessonsFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: Lesson.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    private var dataSource = [Message]()
    private var lastQuestion: Question?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as? AnswerableView)?.delegate = self
        
        collectionView.registerNib(UINib(nibName: Constants.CellNibName, bundle: nil), forCellWithReuseIdentifier: Constants.CellReuseIdentifier)
        addKeyboardObservers()
        
        fetchLessons()
        
        if APIManager.sharedInstance.logined {
            requestNextQuestion()
        } else {
            login()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllExeptLessons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let offset = CGRectGetMinY(senseiImageView.frame)
        collectionView.contentInset.top = offset
    }
    
    // MARK: - Private
    
    private func fetchLessons() {
        var error: NSError? = nil
        if !lessonsFetchedResultController.performFetch(&error) {
            println("Failed to fetch user messages with error: \(error)")
            return
        }
        if let lessons = lessonsFetchedResultController.fetchedObjects as? [Lesson] {
            dataSource += lessons.map {$0 as Message}
            reloadSectionAnimated()
        }
    }
    
    private func requestLessonsHistory() {
        APIManager.sharedInstance.lessonsHistory()
    }
    
    private func requestNextQuestion() {
        APIManager.sharedInstance.nextQuestionyWithCompletion { [weak self](question, error) -> Void in
            if question == nil && error == nil {
                self?.requestLessonsHistory()
            } else if let question = question {
                self?.askQuestion(question)
            }
        }
    }
    
    private func askQuestion(question: Question) {
        lastQuestion = question
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
        
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
            self.collectionView.insertItemsAtIndexPaths(indexPathes)
        }, completion: { [unowned self] (finished) -> Void in
            self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
            if scroll {
                println("maxContentOffset = \(self.maxContentOffset)")
                self.collectionView.setContentOffset(self.maxContentOffset, animated: true)
            }
            if let completion = completion {
                completion()
            }
        })
    }
    
    private func deleteMessageAtIndexPath(indexPath: NSIndexPath) {
        let message = dataSource.removeAtIndex(indexPath.item)
        if message is Lesson {
            APIManager.sharedInstance.blockLessonWithId((message as! Lesson).lessonId, handler: nil)
        }
        
        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
        }, completion: nil)
    }
    
    func removeAllExeptLessons() {
        dataSource = dataSource.filter { $0 is Lesson }
        collectionView.reloadData()
        collectionView.contentInset.bottom = collectionViewBottomContentInset
    }
    
    func reloadSectionAnimated() {
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
            self.collectionView.reloadSections(NSIndexSet(index: 0))
        }, completion: { [unowned self] (finished) -> Void in
            self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
            self.collectionView.setContentOffset(self.maxContentOffset, animated: true)
        })
    }
    
    func login() {
        // TODO: - DELETE HARDCODED IDFA
        let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
//        let idfa = "8B83C19B-E20F-4179-9B1D-E65CA6494F36"
//        let idfa = NSUUID().UUIDString
        let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
        println("IDFA = \(idfa)")
        println("timezone = \(currentTimeZone)")
        APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone) { [weak self] (error) -> Void in
            if let error = error {
                println("Failed to login with error \(error)")
            } else {
                println("Logined successfuly")
                self?.requestNextQuestion()
            }
        }
    }
    
    // MARK: - Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if size.height > senseiBottomSpaceConstraint.constant {
            view.layoutIfNeeded()
            self.collectionView.contentInset.bottom = size.height - Constants.DefaultBottomSpace + collectionViewBottomContentInset
            UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [unowned self] () -> Void in
                self.senseiBottomSpaceConstraint.constant = size.height
                self.collectionView.contentOffset = self.maxContentOffset
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        view.layoutIfNeeded()
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [unowned self] () -> Void in
            self.senseiBottomSpaceConstraint.constant = Constants.DefaultBottomSpace
            self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
            self.view.layoutIfNeeded()
        }, completion: nil)
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

// MARK: - AnswerableViewDelegate

extension SenseiViewController: AnswerableViewDelegate {
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: String) {
        addMessages([Answer(answer: answer)], scroll: true) { [weak self] in
            if let question = self?.lastQuestion where question.id != nil {
                APIManager.sharedInstance.answerQuestionWithId(question.id!, answerText: answer) { [weak self] (error) -> Void in
                    if error == nil {
                        self?.requestNextQuestion()
                    }
                }
            }
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

// MARK: - NSFetchedResultsControllerDelegate

extension SenseiViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let lesson = anObject as? Lesson {
            switch type {
                case .Delete:
                    dataSource = dataSource.filter() {
                        if $0 is Lesson {
                            return ($0 as! Lesson).date != lesson.date
                        }
                        return true
                    }
                    println("Deleted \(lesson.date)")
                case .Insert:
                    dataSource.append(lesson as Message)
                    println("Inserted \(lesson.date)")
                    break
                default:
                    break
            }

        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        dataSource.sort { $0.date.compare($1.date) == .OrderedAscending }
        reloadSectionAnimated()
    }
}
