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
        static let MinOpacity = CGFloat(0.2)
        static let DefaultCellHeight = CGFloat(30.0)
        static let DefaultBottomSpace = CGFloat(80.0)
        static let CollectionContentInset = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 76)
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var senseiBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var senseiImageView: UIImageView!
    
    private lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(SpeechBubbleCollectionViewCellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    private var maxContentOffset: CGPoint {
        let y = collectionView.contentSize.height - CGRectGetHeight(collectionView.frame) + collectionView.contentInset.bottom + min(0, bottomContentInset)
        return CGPoint(x: -Constants.CollectionContentInset.left, y: max(y, -collectionView.contentInset.top))
    }
    
    private var bottomContentInset: CGFloat {
        if dataSource.count > 0 {
            var index = dataSource.count - 1
            var height: CGFloat = 0
            while index > -1 && dataSource[index] is AnswerMessage {
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
    
    private var lastNotUserItemIndex: Int? {
        var index = dataSource.count - 1
        while index > -1 && dataSource[index] is AnswerMessage {
            index--
        }
        return index > -1 ? index: nil
    }
    
    private var isTopViewController: Bool {
        if let navigationController = navigationController, senseiTabController = parentViewController as? SenseiTabController {
            return navigationController.topViewController == senseiTabController
        }
        return false
    }
    
    private var previousApplicationState = UIApplicationState.Background
    private var dataSource = [Message]()
    private var lastQuestion: Question?
    private var lastAffirmation: Affirmation?
    private var lastVisualisation: Visualization?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (view as? AnswerableView)?.delegate = self
        collectionView.registerNib(UINib(nibName: SpeechBubbleCollectionViewCellNibName, bundle: nil), forCellWithReuseIdentifier: SpeechBubbleCollectionViewCellIdentifier)
        collectionView.contentInset = Constants.CollectionContentInset
        fetchLessons()
        addApplicationObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tutorialViewController?.tutorialHidden = true
        if APIManager.sharedInstance.logined {
            APIManager.sharedInstance.lessonsHistoryCompletion(nil)
        }
        addKeyboardObservers()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showLastReceivedVisualisation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllExeptLessons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.contentInset.top = CGRectGetMinY(senseiImageView.frame)
    }
    
    // MARK: - Private
    // MARK: Data Source Operations
    
    private func fetchLessons() {
        var error: NSError? = nil
        if !self.lessonsFetchedResultController.performFetch(&error) {
            println("Failed to fetch user messages with error: \(error)")
            self.login()
            return
        }
        

        if let lessons = self.lessonsFetchedResultController.fetchedObjects as? [Lesson] {
            self.dataSource += lessons.map { $0 as Message }
            self.reloadSectionAnimated(true)
        }
        self.login()
    }
    
    private func insertMessage(message: Message, scroll: Bool) {
        var inserIndex: Int? = nil
        if dataSource.count > 1 {
            for index in 0..<(dataSource.count - 1) {
                if dataSource[index].date.compare(message.date) == .OrderedAscending && dataSource[index + 1].date.compare(message.date) == .OrderedDescending {
                    inserIndex = index + 1
                    break
                }
            }
        }
        if let inserIndex = inserIndex {
            dataSource.insert(message, atIndex: inserIndex)
            let indexPath = NSIndexPath(forItem: inserIndex, inSection: 0)
            collectionView.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView.insertItemsAtIndexPaths([indexPath])
                }, completion: { [unowned self] (finished) -> Void in
                    self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
                    if scroll {
                        self.scrollToItemAtIndexPath(indexPath, animated: true)
                    }
                })
        } else {
            addMessages([message], scroll: true, completion: nil)
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
                    self.scrollToLastNotUsersItemAnimated(true)
                }
                if let completion = completion {
                    completion()
                }
            })
    }
    
    private func deleteMessageAtIndexPath(indexPath: NSIndexPath) {
        let message = dataSource.removeAtIndex(indexPath.item)
        if let message = message as? Lesson {
            APIManager.sharedInstance.blockLessonWithId((message).lessonId, handler: nil)
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(message)
        }
        
        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
        }, completion: nil)
    }
    
    private func removeAllExeptLessons() {
        dataSource = dataSource.filter { $0 is Lesson }
        collectionView.reloadData()
        collectionView.contentInset.bottom = collectionViewBottomContentInset
    }
    
    // MARK: API Requests
    
    private func login() {
        // TODO: - DELETE HARDCODED IDFA
        
//    #if DEBUG
//        let idfa = "2EAB0742-8A34-4315-8C1E-69E6E0EE6366"
//    #else
//        let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
//    #endif
        let idfa = "8161C71D-7FE6-42B9-912C-16B977B3C08F"
//        let idfa = NSUUID().UUIDString
        let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
        println("IDFA = \(idfa)")
        println("timezone = \(currentTimeZone)")
        APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone) { error in
            if let error = error {
                println("Failed to login with error \(error)")
            } else {
                println("Login is successful. Das ist fantastisch!")
                if let push = (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification {
                    self.handleLaunchViaPush(push)
                    (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification = nil
                } else {
                    APIManager.sharedInstance.lessonsHistoryCompletion(nil)
                }
            }
        }
    }
    
    private func requestNextQuestion() {
        APIManager.sharedInstance.nextQuestionyWithCompletion { [weak self](question, error) -> Void in
            if question == nil && error == nil {
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
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
    
    // MARK: UI Operations
    
    private func scrollToItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        if let attributes = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
            let offsetY = CGRectGetMinY(attributes.frame) - collectionView.contentInset.top
            collectionView.setContentOffset(CGPoint(x: -Constants.CollectionContentInset.left, y: offsetY), animated: animated)
        }
    }
    
    private func scrollToLastNotUsersItemAnimated(animated: Bool) {
        if let index = lastNotUserItemIndex {
            self.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: animated)
        }
    }
    
    private func reloadSectionAnimated(animated: Bool) {
        if animated {
            collectionView.performBatchUpdates({ [unowned self] in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
            }, completion: { [unowned self] finished in
                self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
                self.scrollToLastNotUsersItemAnimated(true)
            })
        } else {
            collectionView.reloadData()
            collectionView.contentInset.bottom = collectionViewBottomContentInset
            scrollToLastNotUsersItemAnimated(false)
        }
    }
    
    // MARK: Push Handling
    
    private func addApplicationObservers() {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] notification in
            self.previousApplicationState = UIApplicationState.Background
            self.lastAffirmation = nil
            self.lastVisualisation = nil
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [unowned self]notification in
            self.previousApplicationState = UIApplicationState.Active
        }
        NSNotificationCenter.defaultCenter().addObserverForName(ApplicationDidReceiveRemotePushNotification, object: nil, queue: nil) { [unowned self] notification in
            if let userInfo = notification.userInfo, push = PushNotification(userInfo: userInfo) {
                println("Push Info = \(userInfo)")
                if UIApplication.sharedApplication().applicationState == .Inactive && self.previousApplicationState == .Background {
                    if !self.isTopViewController {
                        self.navigationController?.popToRootViewControllerAnimated(false)
                        (self.navigationController?.viewControllers.first as? SenseiTabController)?.showSenseiViewController()
                    }
                    self.handleLaunchViaPush(push)
                } else {
                    self.handleReceivedPushNotification(push)
                }
            }
        }
    }
    
    private func handleReceivedPushNotification(push: PushNotification) {
        switch push.type {
            case .Lesson:
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
            case .Affirmation:
                if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                    if let date = push.date {
                        affirmation.date = date
                    }
                    self.insertMessage(affirmation, scroll: self.isTopViewController)
                }
            case .Visualisation:
                self.lastVisualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue))
                if self.isTopViewController {
                    self.showLastReceivedVisualisation()
                }
            }
    }
    
    private func handleLaunchViaPush(push: PushNotification) {
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] error in
            switch push.type {
                case .Lesson:
                    let index = self.dataSource.find {
                        let idsEqual = $0.id == push.id
                        if let pushDate = push.date {
                            println("\(pushDate.timeIntervalSince1970) \($0.date.timeIntervalSince1970)")
                            println("\($0)")
                            let isDateEqueal = $0.date.compare(pushDate) == .OrderedSame
                            return idsEqual && isDateEqueal
                        }
                        return idsEqual
                    }
                    if let index = index {
                        self.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: true)
                    }
                case .Affirmation:
                    if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                        if let date = push.date {
                            affirmation.date = date
                        }
                        self.insertMessage(affirmation, scroll: true)
                    }
                case .Visualisation:
                    if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                        self.showVisualisation(visualisation)
                    }
            }
        }
    }
    
    private func showLastReceivedVisualisation() {
        if let visualisation = lastVisualisation {
            showVisualisation(visualisation)
            self.lastVisualisation = nil
        }
    }
    
    private func showVisualisation(visualisation: Visualization) {
        if let image = visualisation.picture {
            let scaledFontSize = CGFloat(visualisation.scaledFontSize.floatValue)
            let attributedText = NSAttributedString(string: visualisation.text, attributes: Visualization.outlinedTextAttributesWithFontSize(scaledFontSize))
            let imagePreviewController = TextImagePreviewController.imagePreviewControllerWithImage(image)
            imagePreviewController.attributedText = attributedText
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.window?.rootViewController?.presentViewController(imagePreviewController, animated: true, completion: nil)
        }
    }
    
    // MARK: Keyboard
    
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SpeechBubbleCollectionViewCellIdentifier, forIndexPath: indexPath) as! SpeechBubbleCollectionViewCell
        cell.delegate = self
        let message = dataSource[indexPath.item]
        cell.text = message.text
        cell.type = message is AnswerMessage ? SpeechBubbleCollectionViewCellType.Me : SpeechBubbleCollectionViewCellType.Sensei
        return cell;
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SenseiViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        sizingCell.text = dataSource[indexPath.item].text
        let width = CGRectGetWidth(UIEdgeInsetsInsetRect(collectionView.bounds, Constants.CollectionContentInset))
        sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: width, height: Constants.DefaultCellHeight)
        let size = sizingCell.systemLayoutSizeFittingSize(CGSize(width: width, height: CGFloat.max), withHorizontalFittingPriority: 1000, verticalFittingPriority: 50)
        return size
    }
}

// MARK: - AnswerableViewDelegate

extension SenseiViewController: AnswerableViewDelegate {
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: Answer) {
        let answerMessage = AnswerMessage(answer: answer)
        addMessages([answerMessage], scroll: true) { [weak self] in
            if let question = self?.lastQuestion where question.questionId != nil {
                APIManager.sharedInstance.answerQuestionWithId(question.id, answerText: "\(answerMessage)") { [weak self] (error) -> Void in
                    if error == nil {
                        self?.requestNextQuestion()
                    }
                }
            }
        }
        println("\(self) submitted answer: \(answerMessage.text)")
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
    
    func speechBubbleCollectionViewCellDidYes(cell: SpeechBubbleCollectionViewCell) {}
    
    func speechBubbleCollectionViewCellDidNo(cell: SpeechBubbleCollectionViewCell) {}
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
        reloadSectionAnimated(isTopViewController)
    }
}
