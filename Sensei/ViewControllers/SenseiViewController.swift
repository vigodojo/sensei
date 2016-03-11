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
    
    private struct ControlNames {
        static let AffirmationsButton = "AffirmationsButton"
        static let VisualisationsButton = "VisualisationsButton"
    }
    
    private struct Constants {
        static let MinOpacity = CGFloat(0.2)
        static let DefaultCellHeight = CGFloat(30.0)
        static let DefaultBottomSpace = CGFloat(36.0)
        static let ToAffirmationsSegue = "Go To Affirmations"
        static let ToVisualisationsSegue = "Go To Visualisations"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var fadingGradientView: FadingGradientView!
    @IBOutlet weak var senseiBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var senseiImageView: AnimatableImageView!
    @IBOutlet weak var affirmationsButton: UIButton!
    @IBOutlet weak var visualisationsButton: UIButton!
	@IBOutlet weak var fadingImageView: UIImageView!
    @IBOutlet weak var senseiTapView: UIView!
    
    private var standUpTimer: NSTimer?
    private lazy var shouldReload: Bool = false
    private var notificationReceived: Bool = false
    private var previousApplicationState = UIApplicationState.Background
    private var dataSource = [Message]()
    private var lastQuestion: QuestionProtocol?
    private var lastAffirmation: Affirmation?
    private var lastVisualisation: Visualization?

	private lazy var transparrencyGradientLayer: CAGradientLayer = {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [UIColor(white: 0.0, alpha: 1.0).CGColor, UIColor(white: 0.0, alpha: 0.0).CGColor]
		gradientLayer.locations = [CGFloat(0.0), CGFloat(0.5)]
		gradientLayer.startPoint = CGPointZero
		gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.6)
		return gradientLayer
	}()
    
    private lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(RightSpeechBubbleCollectionViewCellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    private var collectionViewContentInset: UIEdgeInsets {
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        var rightInset: CGFloat = 0
        switch (screenHeight) {
            case 568: rightInset = 70.0 //iphone 5s
            case 667: rightInset = 80.0 //iphone 6s
            case 736: rightInset = 90.0 //iphone 6sPlus
            default: rightInset = 60.0 //iphone 4s
        }
        
        return UIEdgeInsets(top: 0, left: 11.0, bottom: bottomContentInset, right: rightInset)
    }
    
    private var topContentInset: CGFloat {
        var top = CGRectGetMinY(senseiImageView.frame)
        if dataSource.count > 0 {
            let height = caluclateSizeForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)).height
            top = collectionView.frame.size.height - bottomContentInset - height
        }
        return top
    }
    
    private var bottomContentInset: CGFloat {
        let bottomCollectionViewOffset: CGFloat = 35.0
        let calcHeight = CGRectGetHeight(senseiImageView.frame) - bottomCollectionViewOffset
        return max(0, calcHeight * 0.8)
    }
    
    private lazy var lessonsFetchedResultController: NSFetchedResultsController = { [unowned self] in
        let fetchRequest = NSFetchRequest(entityName: Lesson.EntityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Lesson.entityMapping.primaryProperty, ascending: true)]
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultController.delegate = self
        return fetchedResultController
    }()
    
    private var isTopViewController: Bool {
        if let navigationController = navigationController, senseiTabController = parentViewController as? SenseiTabController {
            return navigationController.topViewController == senseiTabController
        }
        return false
    }
    
    func isLastAffirmation() -> Bool {
        return lastAffirmation != nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        (view as? AnswerableView)?.delegate = self
        collectionView.registerNib(UINib(nibName: RightSpeechBubbleCollectionViewCellNibName, bundle: nil), forCellWithReuseIdentifier: RightSpeechBubbleCollectionViewCellIdentifier)
        collectionView.registerNib(UINib(nibName: LeftSpeechBubbleCollectionViewCellNibName, bundle: nil), forCellWithReuseIdentifier: LeftSpeechBubbleCollectionViewCellIdentifier)
		fadingImageView.layer.mask = transparrencyGradientLayer
        collectionView.contentInset = collectionViewContentInset

        if TutorialManager.sharedInstance.completed {
            fetchLessons()
        } else {
            login()
        }
        
        addApplicationObservers()
        addSenseiGesture()
//        showSitSenseiAnimation()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialDidHideNotification:"), name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishTutorialNotificatin:"), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishUpgradeNotificatin:"), name: TutorialManager.Notifications.DidFinishUpgrade, object: nil)
    }
    
    func showSitSenseiAnimation() {
        if SenseiManager.sharedManager.senseiSitting {
            senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            senseiImageView.hidden = false
            print("Sensei Sit L:136")
            
            if !TutorialManager.sharedInstance.completed {
                return
            }

            if (SenseiManager.sharedManager.showSenseiStandAnimation || SenseiManager.sharedManager.shouldSitBowAfterOpening) && !SenseiManager.sharedManager.isSleepTime() {
                if SenseiManager.sharedManager.showSenseiStandAnimation {
                    SenseiManager.sharedManager.showSenseiStandAnimation = false
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(1) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    print("Sensei Bows L:147")

                    SenseiManager.sharedManager.animateSenseiBowsInImageView(self.senseiImageView, completion: { (finished) -> Void in
                        self.standUpSensei()
                    })
                }
            } else if TutorialManager.sharedInstance.completed && SenseiManager.sharedManager.isSleepTime() {
                setupAwakeAnimationTimer()
            }
        } else {
            senseiImageView.image = SenseiManager.sharedManager.standingImage()
            senseiImageView.hidden = false
            print("Sensei Stand L:157")
            
            if !TutorialManager.sharedInstance.completed {
                return
            }

            if standUpTimer != nil {
                standUpTimer?.invalidate()
                standUpTimer = nil
            }
            standUpTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "standBowSensei:", userInfo: nil, repeats: false)
            print("Sensei Timer To Stand Bow L:168")
        }
    }
    
    func setupAwakeAnimationTimer() {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let timeComponents = sleepTime.end.timeComponents()
        let nextDate = NSCalendar.currentCalendar().nextDateAfterDate(NSDate(), matchingComponents: timeComponents, options: NSCalendarOptions.MatchNextTime)
        
        if standUpTimer != nil {
            standUpTimer?.invalidate()
            standUpTimer = nil
        }
        standUpTimer = NSTimer(fireDate: nextDate!, interval: 0, target: self, selector: "standSenseiUpTimerAction:", userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(standUpTimer!, forMode: NSRunLoopCommonModes)
        print("Sensei Timer To Stand Up L:168")
    }
    
    func standBowSensei(timer: NSTimer) {
        SenseiManager.sharedManager.animateSenseiStandsBowsInImageView(self.senseiImageView, completion: nil)
    }
    
    func standSenseiUpTimerAction(timer: NSTimer) {
        standUpTimer = nil
        SenseiManager.sharedManager.saveLastActiveTime()
        senseiImageView.stopAnimatableImageAnimation()
        standUpSensei()
    }
    
    func standUpSensei() {
        print("Sensei Stands Up L:147")
        SenseiManager.sharedManager.animateSenseiSittingInImageView(self.senseiImageView, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tutorialViewController?.hideTutorialAnimated(false)
        collectionView.contentInset.bottom = bottomContentInset
        
        if !APIManager.sharedInstance.loggingIn {
            if !APIManager.sharedInstance.logined {
                login()
            } else if TutorialManager.sharedInstance.completed {
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
            }
        }
        
        if SenseiManager.sharedManager.senseiSitting || SenseiManager.sharedManager.isSleepTime() || SenseiManager.sharedManager.shouldSitBowAfterOpening {
            SenseiManager.sharedManager.shouldSitBowAfterOpening = false
            senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            print("Sensei Sit L:221")
            
        } else {
            senseiImageView.image = SenseiManager.sharedManager.standingImage()
            print("Sensei Sit L:225")
        }
        
        senseiImageView.hidden = false

        if TutorialManager.sharedInstance.completed && SenseiManager.sharedManager.isSleepTime() {
            setupAwakeAnimationTimer()
        }
        if dataSource.count > 0 {
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: dataSource.count-1, inSection: 0), atScrollPosition: .Top, animated: false)
        }
        addKeyboardObservers()
        addTutorialObservers()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let upgraded = UpgradeManager.sharedInstance.isProVersion()
        let upgradeCompleted = TutorialManager.sharedInstance.upgradeCompleted
        
        if !TutorialManager.sharedInstance.completed {
            if let _ = TutorialManager.sharedInstance.lastCompletedStepNumber {
                dispatchTutorialToAppropriateViewController()
            } else {
                TutorialManager.sharedInstance.nextStep()
            }
        } else if upgraded && !upgradeCompleted {
            TutorialManager.sharedInstance.nextUpgradedStep()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeAllExeptLessons()
        removeKeyboardObservers()
        removeTutorialObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeAllExeptLessons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		transparrencyGradientLayer.frame = fadingImageView.bounds
        collectionView.contentInset.top = topContentInset
        collectionView.contentInset.bottom = bottomContentInset
    }
    
    // MARK: - Private
    // MARK: Data Source Operations
    
    private func fetchLessons() {
        var error: NSError? = nil
        do {
            try self.lessonsFetchedResultController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print("Failed to fetch user messages with error: \(error)")
            self.login()
            return
        }

        print("START: \(NSDate())")
        if let lessons = self.lessonsFetchedResultController.fetchedObjects as? [Lesson] {
            self.dataSource = lessons.map { $0 as Message }
            self.reloadSectionAnimated(false)
        }
        print("END: \(NSDate())")
        self.login()
    }
    
    private func insertMessage(message: Message, scroll: Bool) {
        var inserIndex: Int? = nil
        if dataSource.count > 1 {
            dataSource.append(message)
            dataSource = dataSource.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending})

            for index in 0..<(dataSource.count) {
                if dataSource[index].date.compare(message.date) == .OrderedSame {
                    inserIndex = index
                }
            }
        }
        if let inserIndex = inserIndex {
            let indexPath = NSIndexPath(forItem: inserIndex, inSection: 0)
            collectionView.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }, completion: { [unowned self] (finished) -> Void in
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
        if messages.count == 0 {
            return
        }
        self.collectionView.contentInset.top = self.topContentInset
        if self.parentViewController != nil {
            collectionView.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView.insertItemsAtIndexPaths(indexPathes)
            }, completion: { [unowned self] (finished) -> Void in
                if scroll {
                    self.scrollToLastItemAnimated(true)
                }
                if let completion = completion {
                    self.configureBubles()
                    completion()
                }
            })
        } else {
            removeAllExeptLessons()
        }
    }
    
    func addMsesage(message: Message) {
        addMessages([message], scroll: true, completion: nil)
    }
    
    private func deleteMessageAtIndexPath(indexPath: NSIndexPath) {
        let message = dataSource.removeAtIndex(indexPath.item)
        if let message = message as? Lesson {
            APIManager.sharedInstance.blockLessonWithId((message).itemId, handler: nil)
            CoreDataManager.sharedInstance.managedObjectContext!.deleteObject(message)
        }
        
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
        }) { [unowned self] (finished) -> Void in
            self.changeTopInsets()
        }
    }
    
    private func removeAllExeptLessons() {
        dataSource = dataSource.filter { $0 is Lesson }
        collectionView.reloadData()
    }
    
    private func changeTopInsets() {
        let shouldReload = collectionView.contentOffset.y == -collectionView.contentInset.top
        self.collectionView.contentInset.top = self.topContentInset
        if shouldReload {
            collectionView.setContentOffset(CGPoint(x: 0.0/*collectionView.contentOffset.x*/, y: -collectionView.contentInset.top), animated: true)
        }
        configureBubles()
    }
    // MARK: API Requests
    
    private func login() {
        if APIManager.sharedInstance.logined {
            return
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") == nil {
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "AutoUUID")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
//		let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
        
        let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
        print("IDFA = \(idfa)")
        print("timezone = \(currentTimeZone)")
        APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone) { error in
            if let error = error {
                print("Failed to login with error \(error)")
            } else {
                print("Login is successful. Das ist fantastisch!")
                if let push = (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification {
                    self.handleLaunchViaPush(push)
                    (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification = nil
                } else if TutorialManager.sharedInstance.completed {
                    APIManager.sharedInstance.lessonsHistoryCompletion(nil)
                }
            }
        }
    }
    
    func animateQuestionAnimation(question: QuestionProtocol) {
        if let animatableimage = (question as! QuestionTutorialStep).animatableImage {
            self.senseiImageView.animateAnimatableImage(animatableimage, completion: { [unowned self](finished) -> Void in
                self.senseiImageView.image = animatableimage.images.last
                self.addMessages([question], scroll: false) {
                    (self.view as? AnswerableView)?.askQuestion(question)
                }
            })
        }
    }
    
    // MARK: UI Operations
    
    private func scrollToItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        if let attributes = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
            let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - bottomContentInset
            let offs = CGRectGetMaxY(attributes.frame) - collectionViewHeightWithoutBottomInset
            collectionView.contentInset.top = topContentInset
            collectionView.performBatchUpdates({ [unowned self]() -> Void in
                self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: offs), animated: animated)
            }, completion: { [unowned self] finished in
                self.configureBubles()
            })
        }
    }
    
    private func scrollToLastItemAnimated(animated: Bool) {
        if dataSource.count > 0 {
            self.scrollToItemAtIndexPath(NSIndexPath(forItem: dataSource.count-1, inSection: 0), animated: animated)
        }
    }
    
    private func reloadSectionAnimated(animated: Bool) {
        if dataSource.count == 0 {
            collectionView.reloadData()
            return;
        }
        if animated {
            collectionView.performBatchUpdates({ [unowned self] in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
            }, completion: { [unowned self] finished in
                self.collectionView.contentInset.top = self.topContentInset
                self.scrollToLastItemAnimated(true)
            })
        } else {
            self.collectionView.reloadSections(NSIndexSet(index: 0))
            collectionView.contentInset.top = topContentInset
            scrollToLastItemAnimated(false)
        }
    }

	private func caluclateSizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
		let fullWidth = collectionView.frame.size.width - collectionViewContentInset.left - collectionViewContentInset.right
		let message = dataSource[indexPath.item]
        sizingCell.attributedText = attributedCellTextAtIndexPath(indexPath)
		sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: fullWidth, height: Constants.DefaultCellHeight)
		sizingCell.textView.layoutIfNeeded()
        
		if #available(iOS 9, *) {
			return sizingCell.systemLayoutSizeFittingSize(CGSize(width: fullWidth, height: Constants.DefaultCellHeight))
		} else  {
			let size = sizingCell.systemLayoutSizeFittingSize(CGSize(width: fullWidth, height: Constants.DefaultCellHeight), withHorizontalFittingPriority: 1000, verticalFittingPriority: 50)
			let textSize = SpeechBubbleCollectionViewCell.sizeForText(sizingCell.text, maxWidth: fullWidth, type: message is AnswerMessage ? .Me : .Sensei)
			return CGSize(width: min(size.width, textSize.width), height: size.height)
		}
	}

    // MARK: Sensei Gesture
    
    func addSenseiGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: "senseiTapped:")
        tapGesture.numberOfTapsRequired = 1
        senseiTapView.addGestureRecognizer(tapGesture)
    }
    
    func senseiTapped(recognizer: UITapGestureRecognizer) {
        if !senseiImageView.layerAnimating() && TutorialManager.sharedInstance.completed {
            if SenseiManager.sharedManager.senseiSitting {
                SenseiManager.sharedManager.animateSenseiBowsInImageView(senseiImageView, completion: nil)
            } else {
                SenseiManager.sharedManager.animateSenseiStandsBowsInImageView(senseiImageView, completion: nil)
            }
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
            if self.previousApplicationState == .Background && TutorialManager.sharedInstance.completed {
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
            }
            self.previousApplicationState = UIApplicationState.Active
            
            if !self.notificationReceived {
                self.showSitSenseiAnimation()
            }
            if !TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.currentStep is QuestionTutorialStep {
                (self.view as? AnswerableView)?.askQuestion(TutorialManager.sharedInstance.currentStep as! QuestionTutorialStep)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(ApplicationDidReceiveRemotePushNotification, object: nil, queue: nil) { [unowned self] notification in
            if let userInfo = notification.userInfo, push = PushNotification(userInfo: userInfo) {
                if push.type == .Visualisation {
                    self.notificationReceived = true
                }
                print("Push Info = \(userInfo)")
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
    
    func didEnterBackground() {
        if TutorialManager.sharedInstance.completed {
            self.senseiImageView.hidden = true
        }
        self.senseiBottomSpaceConstraint.constant = Constants.DefaultBottomSpace
        self.transparrencyGradientLayer.startPoint = CGPointZero
        self.view.layoutIfNeeded()
        (self.view as? AnswerableView)?.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func didBecomeActive() {
        SenseiManager.sharedManager = SenseiManager()
        
        if SenseiManager.sharedManager.senseiSitting || (!TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.currentStep?.number < 3) {
            self.senseiImageView.image = SenseiManager.sharedManager.sittingImage()
        } else {
            self.senseiImageView.image = SenseiManager.sharedManager.standingImage()
        }
        self.senseiImageView.hidden = false
    }
    
    func addLessonFromPush(push: PushNotification) {
        if push.date == nil {
            return
        }
        if abs((push.date?.timeIntervalSinceNow)!) < 60*60 {
            if let _ = CoreDataManager.sharedInstance.fetchObjectsWithEntityName("Lesson", sortDescriptors: [], predicate: NSPredicate(format: "date == %@", push.date!))?.first {
                return
            }
            
            let lesson = CoreDataManager.sharedInstance.createObjectForEntityWithName("Lesson") as! Lesson
            lesson.itemId = push.id
            var items = push.alert.componentsSeparatedByString(":")
            
            lesson.preText = items.first!
            items.removeAtIndex(0)
            lesson.text = ""
            if items.count > 0 {
                lesson.text = items.joinWithSeparator(":")
            }
            lesson.type = push.type.rawValue
            lesson.date = push.date!
            CoreDataManager.sharedInstance.saveContext()
        }
    }
    
    private func handleReceivedPushNotification(push: PushNotification) {
        addLessonFromPush(push)
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] (error) -> Void in
            switch push.type {
                case .Lesson:
                    if !self.isTopViewController {
                        let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont, NSForegroundColorAttributeName: UIColor.blackColor()])
                        self.tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)
                    }
                case .Affirmation:
                    if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                        if let date = push.date {
                            affirmation.date = date
                        }
                        let items = push.alert.componentsSeparatedByString(":")
                        affirmation.preMessage = items.first!

                        self.lastAffirmation = affirmation

                        if !(self.navigationController?.topViewController is SenseiTabController) || ((self.parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                            let messageText = NSMutableAttributedString(string: affirmation.fullMessage(), attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                            self.tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)

                        }
                    }
                case .Visualisation:
                    self.lastVisualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue))

                    if !(self.navigationController?.topViewController is SenseiTabController) || ((self.parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                        let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                        messageText.addAttribute(NSLinkAttributeName, value: LinkToVisualization, range: NSMakeRange(0, messageText.length))
                        self.tutorialViewController?.showVisualizationMessage(PlainMessage(attributedText: messageText), visualization: self.lastVisualisation)
                    }
            }
        }
    }
    
    override func affirmationTapped(notification: NSNotification) {

    }
    
    override func visualizationTapped(notification: NSNotification) {
        tutorialViewController?.hideTutorialAnimated(true)
        if let visualization = notification.object as? Visualization {
            showVisualisation(visualization)
        } else {
            self.showLastReceivedVisualisation()
        }
    }
    
    private func handleLaunchViaPush(push: PushNotification) {
        addLessonFromPush(push)
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] error in
            switch push.type {
                case .Lesson:
                    let index = self.dataSource.find {
                        let idsEqual = $0.id == push.id
                        if let pushDate = push.date {
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
            imagePreviewController.delegate = self
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.window?.rootViewController?.presentViewController(imagePreviewController, animated: true, completion: nil)
        }
    }
    
    // MARK: Keyboard
    
    override func keyboardWillShowWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        if TutorialManager.sharedInstance.completed {
            return
        }
        if size.height > senseiBottomSpaceConstraint.constant {
            view.layoutIfNeeded()
			let startPoiint = CGPoint(x: 0.0, y: (size.height - Constants.DefaultBottomSpace) / CGRectGetHeight(fadingImageView.frame))
            UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [unowned self] () -> Void in
                self.senseiBottomSpaceConstraint.constant = size.height
                self.collectionView.contentOffset = CGPointMake(0.0/*self.collectionView.contentOffset.x*/,  self.collectionView.contentSize.height - (CGRectGetHeight(self.collectionView.frame) - size.height) + self.collectionView.contentInset.bottom)
				self.transparrencyGradientLayer.startPoint = startPoiint
                self.view.layoutIfNeeded()
            }, completion: { [unowned self] finished in
                self.configureBubles()
            })
        }
    }
    
    override func keyboardWillHideWithSize(size: CGSize, animationDuration: NSTimeInterval, animationOptions: UIViewAnimationOptions) {
        view.layoutIfNeeded()
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationOptions, animations: { [unowned self] () -> Void in
            self.senseiBottomSpaceConstraint.constant = Constants.DefaultBottomSpace
			self.transparrencyGradientLayer.startPoint = CGPointZero
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Tutorial
    
    func tutorialDidHideNotification(notification: NSNotification) {
        self.lastAffirmation = nil
        self.lastVisualisation = nil
    }

    func didFinishTutorialNotificatin(notification: NSNotification) {
        self.affirmationsButton.userInteractionEnabled = true
        self.visualisationsButton.userInteractionEnabled = true
        fetchLessons()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(2) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            if TutorialManager.sharedInstance.completed {
                (UIApplication.sharedApplication().delegate as! AppDelegate).registerForNotifications()
            }
        }
    }
    
    func didFinishUpgradeNotificatin(notification: NSNotification) {
        affirmationsButton.userInteractionEnabled = true
        visualisationsButton.userInteractionEnabled = true
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(1) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("ShowDisclaimer", sender: self)
        }
    }
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        super.didMoveToNextTutorial(tutorialStep)
        
        if !self.isTopViewController || tutorialStep.screen != .Sensei {
            return
        }
        if tutorialStep is QuestionTutorialStep {
            handleQuestionTutorialStep(tutorialStep as! QuestionTutorialStep)
        } else {
            handleTutorialStep(tutorialStep)
        }
    }
    
    private func handleQuestionTutorialStep(questionTutorialStep: QuestionTutorialStep) {
        askQuestion(questionTutorialStep)
    }
    
    private func askQuestion(question: QuestionProtocol) {
        lastQuestion = question

        let delay = self.dataSource.count > 0 ? TutorialManager.sharedInstance.delayForCurrentStep() : 0
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(delay) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            if let _ = (question as! QuestionTutorialStep).animatableImage {
                self.animateQuestionAnimation(question)
            } else {
                self.addMessages([question], scroll: false) {
                    (self.view as? AnswerableView)?.askQuestion(question)
                }
            }
        }
    }
    
    private func handleTutorialStep(tutorialStep: TutorialStep) {
        let delay = self.dataSource.count > 0 ? TutorialManager.sharedInstance.delayForCurrentStep() : 0
        print("step: \(tutorialStep.number); \ndelay: \(delay)")
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(delay) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            if let animatableimage = tutorialStep.animatableImage {
                self.senseiImageView.animateAnimatableImage(animatableimage) { (finished) -> Void in
                    self.senseiImageView.image = animatableimage.images.last
                    self.handleTutorialStepAction(tutorialStep)
                }
            } else if !tutorialStep.requiresActionToProceed {
                self.handleTutorialStepAction(tutorialStep)
            } else {
                if !tutorialStep.text.isEmpty {
                    self.addMessages([tutorialStep], scroll: true, completion: nil)
                }
            }
        }
    }
    
    private func handleTutorialStepAction(tutorialStep: TutorialStep) {
        if !tutorialStep.text.isEmpty {
            self.addMessages([tutorialStep], scroll: true, completion: nil)
        }
        if !TutorialManager.sharedInstance.completed {
            TutorialManager.sharedInstance.nextStep()
        } else if !TutorialManager.sharedInstance.upgradeCompleted {
            TutorialManager.sharedInstance.nextUpgradedStep()
        }
    }
    
    override func enableControls(controlNames: [String]?) {
        self.affirmationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.AffirmationsButton) ?? true
        self.visualisationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.VisualisationsButton) ?? true
    }
    
    private func dispatchTutorialToAppropriateViewController() {
        if let screenName = TutorialManager.sharedInstance.notFinishedTutorialScreenName {
            switch screenName {
                case .Sensei:
                    TutorialManager.sharedInstance.nextStep()
                case .More:
                    (parentViewController as? SenseiTabController)?.showSettingsViewController()
                case .Affirmation:
                    performSegueWithIdentifier(Constants.ToAffirmationsSegue, sender: self)
                case .Visualisation:
                    performSegueWithIdentifier(Constants.ToVisualisationsSegue, sender: self)
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
        let message = dataSource[indexPath.item]
        let identifier = SpeechBubbleCollectionViewCell.reuseIdetifierForBubbleCellType(message is AnswerMessage ? .Me : .Sensei)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! SpeechBubbleCollectionViewCell
        cell.delegate = self
        
        if let lesson = message as? Lesson where (message as! Lesson).isTypeVisualization() {
            cell.visualization = Visualization.visualizationWithNumber(NSNumber(integer: (lesson.itemId as NSString).integerValue))
        }
        cell.attributedText = attributedCellTextAtIndexPath(indexPath)
        cell.showCloseButton((message is Lesson) && (message as! Lesson).isTypeLesson())

		let size = caluclateSizeForItemAtIndexPath(indexPath)
		let width = CGRectGetWidth(UIEdgeInsetsInsetRect(collectionView.bounds, collectionViewContentInset))
        cell.speachBubleOffset = width - size.width
        configureTipForCell(cell)
        return cell
    }
    
    func removeExpiredMessages() {
        for message in dataSource {
            if abs(message.date.timeIntervalSinceNow) > 60*60 {
                CoreDataManager.sharedInstance.deleteManagedObject(message as! NSManagedObject)
            }
        }
        CoreDataManager.sharedInstance.saveContext()
    }
    
    func attributedCellTextAtIndexPath(indexPath: NSIndexPath) -> NSAttributedString {
        var messageBody: NSMutableAttributedString = NSMutableAttributedString(string: "")
        let message = dataSource[indexPath.item]

        if message is Lesson {
            if (message as! Lesson).isTypeVisualization() {
                messageBody = NSMutableAttributedString(string: (message as! Lesson).preText, attributes: [NSLinkAttributeName: LinkToVisualization])
            } else {
                let text = "\((message as! Lesson).preText) \((message as! Lesson).text)"
                messageBody = NSMutableAttributedString(string: text)
            }
        }
        if message is TutorialStep {
            messageBody = NSMutableAttributedString(string: (message as! TutorialStep).text, attributes:  nil)
        }
        
        if message is AnswerMessage {
            messageBody = NSMutableAttributedString(string: (message as! AnswerMessage).text, attributes:  nil)
        }
        
        messageBody.addAttribute(NSFontAttributeName, value: UIFont.speechBubbleTextFont, range: NSMakeRange(0, messageBody.length))
        return messageBody
    }
}

// MARK: - UIScrollViewDelegate

extension SenseiViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        configureBubles()
    }

    func configureBubles() {
        for indexPath in collectionView.indexPathsForVisibleItems() {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SpeechBubbleCollectionViewCell
            configureTipForCell(cell)
        }
    }
    
    func configureTipForCell(cell: SpeechBubbleCollectionViewCell) {
        let frameToIntersect = CGRectMake(0, CGRectGetMinY(senseiImageView.frame) - 10.0, CGRectGetWidth(view.frame), CGRectGetHeight(senseiImageView.frame)/4)
        let cellFrameInView = collectionView.convertRect(cell.frame, toView: view)
        cell.speechBubbleView.showBubbleTip = CGRectIntersectsRect(cellFrameInView, frameToIntersect)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SenseiViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		let width = collectionView.frame.size.width - collectionViewContentInset.left - collectionViewContentInset.right
		let height = caluclateSizeForItemAtIndexPath(indexPath).height
		return CGSize(width: width, height: height)
    }
}

// MARK: - AnswerableViewDelegate

extension SenseiViewController: AnswerableViewDelegate {
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: Answer) {
        let answerMessage = AnswerMessage(answer: answer)
        print(answerMessage.text)
        addMessages([answerMessage], scroll: true) { [weak self] in
            if let question = self?.lastQuestion {
                switch question.questionSubject {
                    case .Name:
                        NSUserDefaults.standardUserDefaults().setObject("\(answerMessage)", forKey: "name_preference")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        Settings.sharedSettings.name = "\(answerMessage)"
                        CoreDataManager.sharedInstance.saveContext()
                    case .Gender:
                        if let gender = Gender(rawValue: answerMessage.text) {
                            Settings.sharedSettings.gender = gender
                        }
                    default:
                        break
                }
            }
            TutorialManager.sharedInstance.nextStep()
        }
        print("\(self) submitted answer: \(answerMessage.text)")
    }
    
    func answerableViewDidCancel(answerableView: AnswerableView) {
        if let question = self.lastQuestion where question.questionSubject == .Gender {
            TutorialManager.sharedInstance.skipStep()
        }
        TutorialManager.sharedInstance.nextStep()
        print("\(self) canceled question")
    }
}

extension SenseiViewController: TextImagePreviewControllerDelegate {
    func textImagePreviewControllerWillDismiss() {
        if self.notificationReceived == true {
            self.notificationReceived = false
            showSitSenseiAnimation()
        }
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
        shouldReload = false
        if let lesson = anObject as? Lesson {
            switch type {
                case .Delete:
                    shouldReload = true
                    dataSource = dataSource.filter() {
                        return $0.date != lesson.date
                    }
                    print("Deleted \(lesson.date)")
                case .Insert:
                    shouldReload = true
                    dataSource.append(lesson as Message)
                    dataSource.sortInPlace { $0.date.compare($1.date) == .OrderedAscending }
                    print("Inserted \(lesson.date)")
                    break
                default:
                    break
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldReload {
            print("START: \(NSDate())")
            reloadSectionAnimated(isTopViewController)
            print("END: \(NSDate())")
            print("Reload")
        }
    }
}
