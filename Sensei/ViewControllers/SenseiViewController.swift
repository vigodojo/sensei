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
    @IBOutlet weak var senseiHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var senseiImageView: AnimatableImageView!
    @IBOutlet weak var affirmationsButton: UIButton!
    @IBOutlet weak var visualisationsButton: UIButton!
	@IBOutlet weak var fadingImageView: UIImageView!
    @IBOutlet weak var senseiTapView: UIView!
    
    private var standUpTimer: NSTimer?
    private lazy var shouldReload: Bool = false
    private lazy var reloadAnimated: Bool = false
    private var notificationReceived: Bool = false
    private var previousApplicationState = UIApplicationState.Background
    private var dataSource = [Message]()
    private var lastQuestion: QuestionProtocol?
    private var lastAffirmation: Affirmation?
    private var lastVisualisation: Visualization?
    
    private var startFromVis = false
    
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as? AnswerableView)?.delegate = self
        collectionView.registerNib(UINib(nibName: RightSpeechBubbleCollectionViewCellNibName, bundle: nil), forCellWithReuseIdentifier: RightSpeechBubbleCollectionViewCellIdentifier)
        collectionView.registerNib(UINib(nibName: LeftSpeechBubbleCollectionViewCellNibName, bundle: nil), forCellWithReuseIdentifier: LeftSpeechBubbleCollectionViewCellIdentifier)
		fadingImageView.layer.mask = transparrencyGradientLayer
        collectionView.contentInset = collectionViewContentInset
        addApplicationObservers()
        addSenseiGesture()
        if let push = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {
            if push.type == .Visualisation {
                startFromVis = true
            }
            notificationReceived = true
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiViewController.tutorialDidHideNotification(_:)), name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiViewController.didFinishTutorialNotificatin(_:)), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiViewController.didFinishUpgradeNotificatin(_:)), name: TutorialManager.Notifications.DidFinishUpgrade, object: nil)

        
        self.appLaunched()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearCalled()
        
        tutorialViewController?.hideTutorialAnimated(false)
        collectionView.contentInset.bottom = bottomContentInset
        
        if UpgradeManager.sharedInstance.isProVersion() && !TutorialManager.sharedInstance.upgradeCompleted {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "TutorialUpgradeCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }

        if !self.startFromVis && !(UpgradeManager.sharedInstance.isProVersion() && !TutorialManager.sharedInstance.upgradeCompleted) {
            showSitSenseiAnimation()
        }
        
        if startFromVis {
            startFromVis = false
            if SenseiManager.sharedManager.senseiSitting || SenseiManager.sharedManager.isSleepTime() || SenseiManager.sharedManager.shouldSitBowAfterOpening {
                SenseiManager.sharedManager.shouldSitBowAfterOpening = false
                senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            } else {
                senseiImageView.image = SenseiManager.sharedManager.standingImage()
            }
            senseiImageView.hidden = false
            if let push = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {
                handleLaunchViaPush(push)
            }
        }
        
        scrollToLastItemAnimated(false)
        if TutorialManager.sharedInstance.completed && SenseiManager.sharedManager.isSleepTime() {
            setupAwakeAnimationTimer()
        }
        
        affirmationsButton.exclusiveTouch = true
        visualisationsButton.exclusiveTouch = true
        addKeyboardObservers()
        addTutorialObservers()
    }
    
    func updateHistory() {
        if (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification == nil {
            self.storeLastItem()
        }

        APIManager.sharedInstance.lessonsHistoryCompletion({ (error) in
            
        })
    }
    
    func storeLastItem() {
        if !TutorialManager.sharedInstance.completed || dataSource.count == 0 {
            return
        }
        dataSource = dataSource.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending})
        
        var lessons = dataSource.filter { $0 is Lesson }

        lessons = lessons.filter {
            ($0 as! Lesson).type.lowercaseString == "l"
        }

        if let lesson = lessons.last as? Lesson {
            NSUserDefaults.standardUserDefaults().setObject(lesson.date, forKey: "LastItem")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func retrieveLastItem() -> (Lesson, Int)? {
        if !TutorialManager.sharedInstance.completed || dataSource.count == 0 {
            return nil
        }
        if let lessonDate = NSUserDefaults.standardUserDefaults().objectForKey("LastItem") as? NSDate {
            for index in 0..<dataSource.count {
                let item = dataSource[index]
                if item.date == lessonDate {
                    return (item as! Lesson, index)
                }
            }
        }
        if dataSource.count > 0 && dataSource.last is Lesson {
            return (dataSource.last as! Lesson, dataSource.count - 1)
        }
        return nil
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
        removeKeyboardObservers()
        removeTutorialObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeAllExeptLessons()
        APIManager.sharedInstance.clearHistory { (error) in
            if error == nil {
                self.removeAllExeptLessons()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        senseiHeightConstraint.constant = UIScreen.mainScreen().bounds.height/4
		transparrencyGradientLayer.frame = fadingImageView.bounds
        collectionView.contentInset.top = topContentInset
        collectionView.contentInset.bottom = bottomContentInset
    }

    //MARK: - Sensei animation
    
    func showSitSenseiAnimation() {
        if SenseiManager.sharedManager.senseiSitting {
            senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            senseiImageView.hidden = false
            
            if !TutorialManager.sharedInstance.completed {
                return
            }
            
            if (SenseiManager.sharedManager.showSenseiStandAnimation || SenseiManager.sharedManager.shouldSitBowAfterOpening) && !SenseiManager.sharedManager.isSleepTime() {
                if SenseiManager.sharedManager.showSenseiStandAnimation {
                    SenseiManager.sharedManager.showSenseiStandAnimation = false
                }
                SenseiManager.sharedManager.standBow = false
                dispatchInMainThreadAfter(delay: 1) {
                    SenseiManager.sharedManager.animateSenseiBowsInImageView(self.senseiImageView, completion: { (finished) -> Void in
                        self.standUpSensei()
                    })
                }
            } else {
                sitBowIfNeeded()
                if TutorialManager.sharedInstance.completed && SenseiManager.sharedManager.isSleepTime() {
                    setupAwakeAnimationTimer()
                }
            }
            SenseiManager.sharedManager.shouldSitBowAfterOpening = false
        } else {
            senseiImageView.image = SenseiManager.sharedManager.standingImage()
            senseiImageView.hidden = false
            
            if !TutorialManager.sharedInstance.completed {
                return
            }
            
            standBowIfNeeded()
        }
    }
    
    func standBowIfNeeded() {
        if !SenseiManager.sharedManager.standBow || self.startFromVis || self.parentViewController == nil {
            return
        }
        
        SenseiManager.sharedManager.standBow = false

        dispatchInMainThreadAfter(delay: 1) {
            self.standBowSensei()
        }
    }
    
    func sitBowIfNeeded() {
        if !SenseiManager.sharedManager.standBow || self.startFromVis || self.parentViewController == nil {
            return
        }
        SenseiManager.sharedManager.standBow = false

        dispatchInMainThreadAfter(delay: 1) {
            self.sitBowSensei()
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
        standUpTimer = NSTimer(fireDate: nextDate!, interval: 0, target: self, selector: #selector(SenseiViewController.standSenseiUpTimerAction(_:)), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(standUpTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func standBowSensei() {
        SenseiManager.sharedManager.animateSenseiStandsBowsInImageView(self.senseiImageView, completion: nil)
    }
    
    func sitBowSensei() {
        SenseiManager.sharedManager.animateSenseiBowsInImageView(self.senseiImageView, completion: nil)
    }
    
    func standSenseiUpTimerAction(timer: NSTimer) {
        standUpTimer = nil
        SenseiManager.sharedManager.saveLastActiveTime()
        senseiImageView.stopAnimatableImageAnimation()
        standUpSensei()
    }
    
    func standUpSensei() {
        SenseiManager.sharedManager.animateSenseiSittingInImageView(self.senseiImageView, completion: nil)
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
        if let lessons = self.lessonsFetchedResultController.fetchedObjects as? [Lesson] {
            self.dataSource = lessons.map { $0 as Message }
            self.reloadSectionAnimated(false, scroll: true, scrollAnimated: false)
        }

        if !APIManager.sharedInstance.logined {
            self.login()
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
        dataSource = dataSource.filter({ (lesson) -> Bool in
            if (lesson as! Lesson).type.lowercaseString == "l" {
                return true
            }
            CoreDataManager.sharedInstance.deleteManagedObject(lesson as! NSManagedObject)
            return false
        })
 
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
                }
                if TutorialManager.sharedInstance.completed {
                    self.storeLastItem()
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
                    if question is TutorialStep && (question as! TutorialStep).number == 1 {
                        self.dispatchInMainThreadAfter(delay: 3) {
                            (self.view as? AnswerableView)?.askQuestion(question)
                        }
                    } else {
                        (self.view as? AnswerableView)?.askQuestion(question)
                    }
                }
            })
        }
    }
    
    // MARK: UI Operations
    
    private func scrollToItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {
        if indexPath.row >= dataSource.count {
            return
        }
        if let attributes = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
            let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - bottomContentInset
            let offs = CGRectGetMaxY(attributes.frame) - collectionViewHeightWithoutBottomInset
            
            collectionView.contentInset.top = topContentInset
            self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: offs), animated: animated)
        }
    }
    
    private func reloadSectionAnimated(animated: Bool, scroll: Bool, scrollAnimated: Bool) {
        if dataSource.count == 0 {
            collectionView.reloadData()
            return;
        }
        
        if animated && collectionView.numberOfSections() > 0 {
            collectionView.performBatchUpdates({ [unowned self] in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
                }, completion: { [unowned self] finished in
                    self.collectionView.contentInset.top = self.topContentInset
                    if scroll {
                        self.scrollToLastItemAnimated(scrollAnimated)
                    }
                })
        } else {
            self.collectionView.reloadData()
            
            collectionView.performBatchUpdates({}, completion: { [unowned self] finished in
                self.collectionView.contentInset.top = self.topContentInset
                if scroll {
                    self.scrollToLastItemAnimated(scrollAnimated)
                }
            })
        }
    }
    
    private func scrollToLastItemAnimated(animated: Bool) {
        if dataSource.count > 0 {
            if let item = retrieveLastItem() where item.1 + 1 < dataSource.count{
                let indexPath = NSIndexPath(forItem: item.1 + 1, inSection: 0)
                scrollToItemAtIndexPath(indexPath, animated: animated)
//                collectionView.scrollToItemAtIndexPath(, atScrollPosition: .Bottom, animated: animated)
            } else {
                let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - bottomContentInset
                let contentSize = self.collectionView.contentSize
                self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: contentSize.height - collectionViewHeightWithoutBottomInset), animated: animated)
            }
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SenseiViewController.senseiTapped(_:)))
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
            self.enteredToBackground()
            
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [unowned self]notification in
            if self.previousApplicationState != .Inactive {
                self.appOpenedFromTray()
            }
            self.previousApplicationState = UIApplicationState.Active
        }

        NSNotificationCenter.defaultCenter().addObserverForName(ApplicationDidReceiveRemotePushNotification, object: nil, queue: nil) { [unowned self] notification in
            self.receivedPush()
            NSLog("prev state: \(self.previousApplicationState)")
            APIManager.sharedInstance.addToLog("received push notfication")

            if let userInfo = notification.userInfo, push = PushNotification(userInfo: userInfo) {
                
                (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification = push
                self.processPushReceiving(push)
            }
        }
    }
    
    func appLaunched() {
        NSLog("*** LAUNCHED")
        
        if TutorialManager.sharedInstance.completed {
            fetchLessons()
        } else {
            login()
        }
        
        if let push = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {

            NSLog("    PUSH WITH TYPE \(push.type)")
        } else {
 
        }
    }
    
    func appOpenedFromTray() {
        NSLog("*** FROM TRAY")
        
        if let push = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {
            NSLog("    PUSH WITH TYPE \(push.type)")
        } else {
            if TutorialManager.sharedInstance.completed {
                self.storeLastItem()
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
            }
            SenseiManager.sharedManager = SenseiManager()
            if let _ = self.parentViewController {
                SenseiManager.sharedManager.standBow = true
            }
            APIManager.sharedInstance.addToLog("become active - self.notificationReceived: \(self.notificationReceived)")
            APIManager.sharedInstance.addToLog("become active - startFromVis: \(self.startFromVis)")

            if !self.startFromVis {
                self.showSitSenseiAnimation()
            }
            if !TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.currentStep is QuestionTutorialStep {
                (self.view as? AnswerableView)?.askQuestion(TutorialManager.sharedInstance.currentStep as! QuestionTutorialStep)
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

        dispatchInMainThreadAfter(delay: 2) {
            if TutorialManager.sharedInstance.completed {
                (UIApplication.sharedApplication().delegate as! AppDelegate).registerForNotifications()
            }
        }
    }
    
    func didFinishUpgradeNotificatin(notification: NSNotification) {
        affirmationsButton.userInteractionEnabled = true
        visualisationsButton.userInteractionEnabled = true
        dispatchInMainThreadAfter(delay: 1) {
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
        
        dispatchInMainThreadAfter(delay: Float(delay)) {
            if let _ = (question as! QuestionTutorialStep).animatableImage {
                self.animateQuestionAnimation(question)
            } else {
                self.addMessages([question], scroll: false) {
                    if question is TutorialStep && (question as! TutorialStep).number == 1 {
                        self.dispatchInMainThreadAfter(delay: 3) {
                            (self.view as? AnswerableView)?.askQuestion(question)
                        }
                    } else {
                        (self.view as? AnswerableView)?.askQuestion(question)
                    }
                }
            }
        }
    }
    
    private func handleTutorialStep(tutorialStep: TutorialStep) {
        let delay = self.dataSource.count > 0 ? TutorialManager.sharedInstance.delayForCurrentStep() : 0
        
        dispatchInMainThreadAfter(delay: Float(delay)) {
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
    
    override func enableControls(controlNames: [String]?) {
        self.affirmationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.AffirmationsButton) ?? true
        self.visualisationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.VisualisationsButton) ?? true
    }
}

// MARK: - Launch options

extension SenseiViewController {
    
    func receivedPush() {
        print("*** PUSH RECEIVED")
        
    }
    
    func enteredToBackground() {
        print("*** ENTERED BACKGROUND")
        (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification = nil
        APIManager.sharedInstance.clearHistory { (error) in
            if error == nil {
                self.removeAllExeptLessons()
            }
        }
//        self.removeAllExeptLessons()
        self.previousApplicationState = UIApplicationState.Background
        self.lastAffirmation = nil
        self.lastVisualisation = nil
        if self.standUpTimer != nil {
            self.standUpTimer?.invalidate()
            self.standUpTimer = nil
        }
    }
    
    func viewWillAppearCalled() {
        print("*** VIEW WILL APPEAR")
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
}

// MARK: - Push Notifications

extension SenseiViewController {
    
    func processPushReceiving(push: PushNotification) {
        notificationReceived = true
        startFromVis = (push.type == .Visualisation)
        addLessonFromPush(push)

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

    private func handleReceivedPushNotification(push: PushNotification) {
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
                    affirmation.preMessage = push.preMessage
                    self.lastAffirmation = affirmation
                    
                    if !(self.navigationController?.topViewController is SenseiTabController) || ((self.parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                        let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                        self.tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)
                    }
                }
            case .Visualisation:
                if let visualization = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                    if !(self.navigationController?.topViewController is SenseiTabController) || ((self.parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                        self.lastVisualisation = visualization
                        let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                        messageText.addAttribute(NSLinkAttributeName, value: LinkToVisualization, range: NSMakeRange(0, messageText.length))
                        self.tutorialViewController?.showVisualizationMessage(PlainMessage(attributedText: messageText), visualization: visualization)
                    }
                }
            }
        }
    }
    
    private func handleLaunchViaPush(push: PushNotification) {
        if push.type == PushType.Visualisation {
            if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                self.showVisualisation(visualisation)
            }
        }
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
                    if let index = index where index < self.dataSource.count {
                        self.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: true)
                    }
                case .Affirmation:
                    if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                        if let date = push.date {
                            affirmation.date = date
                        }
                    }
                    
                case .Visualisation:
                    print("Vis")
                }
        }
    }
    
    func addLessonFromPush(push: PushNotification) {
        if push.date == nil || APIManager.sharedInstance.reachability.isReachable() {
            return
        }
        
        if abs((push.date?.timeIntervalSinceNow)!) < 60*60 {
            if let _ = CoreDataManager.sharedInstance.fetchObjectsWithEntityName("Lesson", sortDescriptors: [], predicate: NSPredicate(format: "date == %@", push.date!))?.first {
                return
            }
            
            let lesson = CoreDataManager.sharedInstance.createObjectForEntityWithName("Lesson") as! Lesson
            lesson.itemId = push.id
            lesson.type = push.type.rawValue
            lesson.date = push.date!
            
            if lesson.isTypeLesson() {
                lesson.text = push.alert
            } else {
                lesson.preText = push.preMessage
                lesson.text = push.alert.stringByReplacingOccurrencesOfString(lesson.preText, withString: "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            }
            CoreDataManager.sharedInstance.saveContext()
            
            let index = self.dataSource.find {
                let idsEqual = $0.id == push.id
                if let pushDate = push.date {
                    let isDateEqueal = $0.date.compare(pushDate) == .OrderedSame
                    return idsEqual && isDateEqueal
                }
                return idsEqual
            }
            if let index = index where index < self.dataSource.count {
                self.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: true)
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
        cell.showCloseButton(false)//(message is Lesson) && (message as! Lesson).isTypeLesson())

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
            } else if (message as! Lesson).isTypeAffirmation() {
                let text = "\((message as! Lesson).preText) \((message as! Lesson).text)"
                messageBody = NSMutableAttributedString(string: text)
            } else {
                messageBody = NSMutableAttributedString(string: (message as! Lesson).text)
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

// MARK: - TextImagePreviewControllerDelegate

extension SenseiViewController: TextImagePreviewControllerDelegate {
    
    func textImagePreviewControllerWillDismiss() {
        if self.startFromVis == true {
            self.startFromVis = false
            if SenseiManager.sharedManager.senseiSitting {
                sitBowIfNeeded()
            } else {
                standBowIfNeeded()
            }
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
        reloadAnimated = false
        if let lesson = anObject as? Lesson {
            switch type {
                case .Delete:
                    shouldReload = true
                    dataSource = dataSource.filter() {
                        return $0.date != lesson.date
                    }
                    print("Deleted \(lesson.date)")
                case .Insert:
                    reloadAnimated = true
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

    func removeDuplicated() {
        var set = Set<NSDate>()
        var sorted = [Message]()
        for lesson in dataSource {
            if !set.contains(lesson.date) {
                sorted.append(lesson)
                set.insert(lesson.date)
            }
        }
        dataSource = sorted
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldReload {
            removeDuplicated()
            reloadSectionAnimated(true, scroll: !reloadAnimated, scrollAnimated: true)//isTopViewController)
        }
    }
}