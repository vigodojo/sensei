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
    
    private enum ScreenHeight: CGFloat {
        case iPhone4 = 480
        case iPhone5 = 568
        case iPhone6 = 667
        case iPhone6plus = 736
    }
    
    private enum SpeechBubbleRightInset: CGFloat {
        case iPhone4 = 60
        case iPhone5 = 70
        case iPhone6 = 80
        case iPhone6plus = 90
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
    private var sitDownTimer: NSTimer?

    private lazy var shouldReload: Bool = false
    private lazy var reloadAnimated: Bool = false
    private var notificationReceived: Bool = false
    private var previousApplicationState = UIApplicationState.Inactive
    private var dataSource = [Message]()
    private var lastQuestion: QuestionProtocol?
    private var lastAffirmation: Affirmation?
    var lastVisualisation: Visualization?
    
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
        NSBundle.mainBundle().loadNibNamed(RightSpeechBubbleCollectionViewCellNibName, owner: self, options: nil)!.first as! SpeechBubbleCollectionViewCell
    }()
    
    private var collectionViewContentInset: UIEdgeInsets {
        var rightInset: SpeechBubbleRightInset = SpeechBubbleRightInset.iPhone4
        if let screenHeight = ScreenHeight(rawValue: UIScreen.mainScreen().bounds.size.height) {
            switch (screenHeight) {
                case .iPhone4: rightInset = SpeechBubbleRightInset.iPhone4 //iphone 4s
                case .iPhone5: rightInset = SpeechBubbleRightInset.iPhone5 //iphone 5s
                case .iPhone6: rightInset = SpeechBubbleRightInset.iPhone6 //iphone 6s
                case .iPhone6plus: rightInset = SpeechBubbleRightInset.iPhone6plus //iphone 6sPlus
            }
        }
        return UIEdgeInsets(top: 0, left: 11.0, bottom: bottomContentInset, right: rightInset.rawValue)
    }
    
    private var topContentInset: CGFloat {
        var top = CGRectGetMinY(senseiImageView.frame)
        if dataSource.count > 0 {
            let height = caluclateSizeForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)).height
            top = collectionView.frame.size.height - bottomContentInset - height
            if top < 0 {
                top = 20.0
            }
        }
        return top
    }
    
    private var bottomContentInset: CGFloat {
        let bottomCollectionViewOffset: CGFloat = 35.0
        let calcHeight = CGRectGetHeight(senseiImageView.frame) - bottomCollectionViewOffset
        return max(0, calcHeight * 0.8)//magic number
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

        appLaunched()
        senseiTapView.userInteractionEnabled = TutorialManager.sharedInstance.completed || UpgradeManager.sharedInstance.isProVersion() && TutorialManager.sharedInstance.upgradeCompleted
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

        if startFromVis {
            if SenseiManager.sharedManager.senseiSitting || SenseiManager.sharedManager.isSleepTime() || SenseiManager.sharedManager.shouldSitBowAfterOpening {
                senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            } else {
                senseiImageView.image = SenseiManager.sharedManager.standingImage()
            }
            senseiImageView.hidden = false
            if let push = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {
                handleLaunchViaPush(push)
            }
        } else if (!(UpgradeManager.sharedInstance.isProVersion() && !TutorialManager.sharedInstance.upgradeCompleted) || TutorialManager.sharedInstance.completed) && tutorialViewController!.splashMaskImageView.hidden {
            if SenseiManager.sharedManager.senseiSitting || SenseiManager.sharedManager.isSleepTime() || SenseiManager.sharedManager.shouldSitBowAfterOpening {
                senseiImageView.image = SenseiManager.sharedManager.sittingImage()
            } else {
                senseiImageView.image = SenseiManager.sharedManager.standingImage()
            }
            showSitSenseiAnimation()
        } else if TutorialManager.sharedInstance.completed {
            setupAwakeAsleepTimer()
        }

        affirmationsButton.exclusiveTouch = true
        visualisationsButton.exclusiveTouch = true
        addKeyboardObservers()
        addTutorialObservers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SenseiViewController.didAuthenticate(_:)), name: APIManager.Notification.DidAuthenticateNotification, object: nil)
        
        enableSenseiInteractionIfNeeded()
    }
    
    func setupAwakeAsleepTimer() {
        if SenseiManager.sharedManager.isSleepTime() {
            setupAwakeAnimationTimer()
        } else {
            setupAsleepAnimationTimer()
        }
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
        
        let lessons = dataSource.filter { $0 is Lesson }
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
            senseiTapView.userInteractionEnabled = false
            TutorialManager.sharedInstance.nextUpgradedStep()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        lastAffirmation = nil
        lastVisualisation = nil
        
        dismissViewController()
        removeKeyboardObservers()
        removeTutorialObservers()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: APIManager.Notification.DidAuthenticateNotification, object: nil)
        storeLastItem()
    }
    
    func dismissViewController() {
        if let viewController = (UIApplication.sharedApplication().delegate as? AppDelegate)?.window?.rootViewController where viewController.presentedViewController != nil && viewController.presentedViewController is TextImagePreviewController {
            viewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !TutorialManager.sharedInstance.completed {
            self.removeAllExeptLessons()
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
            senseiImageView.hidden = false
            
            if !TutorialManager.sharedInstance.completed {
                return
            }
            
            if (SenseiManager.sharedManager.showSenseiStandAnimation || SenseiManager.sharedManager.shouldSitBowAfterOpening) && !SenseiManager.sharedManager.isSleepTime() {
                if startFromVis {
                    return
                }
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
                if TutorialManager.sharedInstance.completed {
                    setupAwakeAsleepTimer()
                }
            }
            SenseiManager.sharedManager.shouldSitBowAfterOpening = false
        } else {
            senseiImageView.hidden = false
            setupAwakeAsleepTimer()

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
        
        invalidateTimer(standUpTimer)
        standUpTimer = NSTimer(fireDate: nextDate!, interval: 0, target: self, selector: #selector(SenseiViewController.standSenseiUpTimerAction(_:)), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(standUpTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func setupAsleepAnimationTimer() {
        let sleepTime = NSCalendar.currentCalendar().isDateInWeekend(NSDate()) ? Settings.sharedSettings.sleepTimeWeekends : Settings.sharedSettings.sleepTimeWeekdays
        let timeComponents = sleepTime.start.timeComponents()
        let nextDate = NSCalendar.currentCalendar().nextDateAfterDate(NSDate(), matchingComponents: timeComponents, options: NSCalendarOptions.MatchNextTime)
        
        invalidateTimer(sitDownTimer)

        sitDownTimer = NSTimer(fireDate: nextDate!, interval: 0, target: self, selector: #selector(SenseiViewController.sitdownSenseiUpTimerAction(_:)), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(sitDownTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func standBowSensei() {
        SenseiManager.sharedManager.animateSenseiStandsBowsInImageView(self.senseiImageView, completion: nil)
    }
    
    func sitBowSensei() {
        if !senseiImageView.layerAnimating() {
            SenseiManager.sharedManager.shouldSitBowAfterOpening = false
            SenseiManager.sharedManager.animateSenseiBowsInImageView(self.senseiImageView, completion: nil)
        }
    }
    
    func standSenseiUpTimerAction(timer: NSTimer) {
        invalidateTimer(standUpTimer)
        SenseiManager.sharedManager.saveLastActiveTime()
        senseiImageView.stopAnimatableImageAnimation()
        setupAsleepAnimationTimer()
        standUpSensei()
    }

    func sitdownSenseiUpTimerAction(timer: NSTimer) {
        invalidateTimer(sitDownTimer)
        senseiImageView.stopAnimatableImageAnimation()
        setupAwakeAnimationTimer()
        sitDownSensei()
    }
    
    func standUpSensei() {
        if !senseiImageView.layerAnimating() {
            SenseiManager.sharedManager.animateSenseiSittingInImageView(self.senseiImageView, completion: nil)
        }
    }
    func sitDownSensei() {
        if !senseiImageView.layerAnimating() {
            SenseiManager.sharedManager.animateSenseiSitDownInImageView(self.senseiImageView, completion: { (finished) in
                self.senseiTapView.userInteractionEnabled = true
            })
        }
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
        if let lessons = self.lessonsFetchedResultController.fetchedObjects as? [Lesson]  {
            if lessons.count > 0 {
                self.dataSource = lessons.map { $0 as Message }
            }
            if !APIManager.sharedInstance.reachability.isReachable() {
                self.reloadSectionAnimated(false, scroll: true, scrollAnimated: false)
                showSitSenseiAnimation()
            }
        }

        if !APIManager.sharedInstance.logined {
            self.login()
        }
    }
    
    func insertMessage(message: Message) {
        
        dataSource.append(message)
        dataSource.sortInPlace { $0.date.compare($1.date) == .OrderedAscending }
        
        var indexInArray = dataSource.count - 1

        for index in 0..<dataSource.count {
            let enumMessage = dataSource[index]
            if enumMessage.date == message.date {
                indexInArray = index
                break
            }
        }
        
        self.collectionView.contentInset.top = self.topContentInset
        if self.parentViewController != nil {
            scrollToItemAtIndexPath(NSIndexPath(forRow: indexInArray, inSection: 0), animated: false)
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
        collectionView.contentInset.top = self.topContentInset
        if parentViewController != nil {
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
        }
    }
    
    func addMsesage(message: Message) {
        addMessages([message], scroll: true, completion: nil)
    }

    func removeAllExeptLessons() {
        dataSource = dataSource.filter { $0 is Lesson }
        dataSource = dataSource.filter({ (lesson) -> Bool in
            if (lesson as! Lesson).type.lowercaseString == "l" {
                return true
            }
            CoreDataManager.sharedInstance.deleteManagedObject(lesson as! NSManagedObject)
            return false
        })
        CoreDataManager.sharedInstance.saveContext()
        collectionView.reloadData()
    }
    
    private func changeTopInsets() {
        let shouldReloadLocal = collectionView.contentOffset.y == -collectionView.contentInset.top
        self.collectionView.contentInset.top = self.topContentInset
        if shouldReloadLocal {
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
//            The same for device
//            NSUserDefaults.standardUserDefaults().setObject(UIDevice.currentDevice().identifierForVendor?.UUIDString, forKey: "AutoUUID")

//            Every time different (for installation)
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "AutoUUID")
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
        let currentTimeZone = NSTimeZone.systemTimeZone().secondsFromGMT / 3600
        APIManager.sharedInstance.loginWithDeviceId(idfa, timeZone: currentTimeZone) { error in
            if let error = error {
                print("Failed to login with error \(error)")
            }
        }
    }
    
    func didAuthenticate(notification: NSNotification) {
        print("Login is successful.")
        if let push = (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification {
            self.handleLaunchViaPush(push)
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotification = nil
        }
        if TutorialManager.sharedInstance.completed {
            self.storeLastItem()
            let oldDataSource = dataSource.filter({ _ in return true})
            
            APIManager.sharedInstance.lessonsHistoryCompletion({ [weak self] (error) in
                guard let strongSelf = self else { return }
                if !strongSelf.tutorialViewController!.splashMaskImageView.hidden {
                    strongSelf.showSitSenseiAnimation()
                }
                if strongSelf.dataSourceEqualTo(oldDataSource) {
                    strongSelf.reloadSectionAnimated(false, scroll: true, scrollAnimated: false)
                }
            })
        }
    }
    
    func dataSourceEqualTo(array: [Message]) -> Bool {
        if dataSource.count != array.count { return false }
        for (l, r) in zip(dataSource, array) {
            if l.id != r.id { return false }
        }
        return true
    }
    
    func address(o: UnsafePointer<Void>) -> Int {
        return unsafeBitCast(o, Int.self)
    }
    
    func animateQuestionAnimation(question: QuestionProtocol) {
        guard let animatableimage = (question as! QuestionTutorialStep).animatableImage else { return }
        senseiImageView.animateAnimatableImage(animatableimage, completion: { [unowned self](finished) -> Void in
            self.senseiImageView.image = animatableimage.images.last
            self.addMessages([question], scroll: false) {
                if question is TutorialStep && (question as! TutorialStep).number == StepIndexes.WhatInYourNameIndex.rawValue {
                    self.dispatchInMainThreadAfter(delay: 3) {
                        (self.view as? AnswerableView)?.askQuestion(question)
                    }
                } else {
                    (self.view as? AnswerableView)?.askQuestion(question)
                }
            }
        })
    }
    
    // MARK: UI Operations
    
    private func scrollToItemAtIndexPath(indexPath: NSIndexPath, animated: Bool) {

        collectionView.layoutIfNeeded()
        if indexPath.row >= dataSource.count {
            return
        }
        if let attributes = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(indexPath) {
            let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - bottomContentInset
            let offset = CGRectGetMaxY(attributes.frame) - collectionViewHeightWithoutBottomInset
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                self.tutorialViewController?.splashMaskImageView.hidden = true
            })
            collectionView.contentInset.top = topContentInset
            collectionView.setContentOffset(CGPoint(x: collectionView.contentOffset.x, y: offset), animated: animated)
        }
    }
    
    private func reloadSectionAnimated(animated: Bool, scroll: Bool, scrollAnimated: Bool) {
        
        if animated && collectionView.numberOfSections() > 0 {
            collectionView.performBatchUpdates({ [unowned self] in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
            }, completion: { [unowned self] finished in
                self.collectionView.contentInset.top = self.topContentInset
                if finished && scroll {
                    self.scrollToLastItemAnimated(scrollAnimated)
                }
            })
        } else {
            CATransaction.begin()
            CATransaction.setCompletionBlock({ 
                self.collectionView.contentInset.top = self.topContentInset
                if scroll {
                    self.scrollToLastItemAnimated(scrollAnimated)
                }
            })
            self.collectionView.reloadData()
        }
    }
    
    private func scrollToLastItemAnimated(animated: Bool) {
        if dataSource.count > 0 {
            if let item = retrieveLastItem() where item.1 + 1 < dataSource.count && TutorialManager.sharedInstance.upgradeCompleted && UpgradeManager.sharedInstance.isProVersion() {
                let indexPath = NSIndexPath(forItem: item.1 + 1, inSection: 0)
                
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.tutorialViewController?.splashMaskImageView.hidden = true
                    self.showSitSenseiAnimation()
                })
                scrollToItemAtIndexPath(indexPath, animated: animated)
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.tutorialViewController?.splashMaskImageView.hidden = true
                    self.showSitSenseiAnimation()
                })
                let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - bottomContentInset
                let contentSize = self.collectionView.contentSize
                self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: contentSize.height - collectionViewHeightWithoutBottomInset), animated: animated)
                CATransaction.commit()
            }
        } else {
            tutorialViewController?.splashMaskImageView.hidden = true
            showSitSenseiAnimation()
        }
    }

	private func caluclateSizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
		let fullWidth = collectionView.frame.size.width - collectionViewContentInset.left - collectionViewContentInset.right
		let message = dataSource[indexPath.item]
        sizingCell.attributedText = attributedCellTextAtIndexPath(indexPath)
		sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: fullWidth, height: Constants.DefaultCellHeight)
        
        sizingCell.setNeedsLayout()
        sizingCell.layoutIfNeeded()
		sizingCell.textView.layoutIfNeeded()
        
		if #available(iOS 9, *) {
            let size = sizingCell.systemLayoutSizeFittingSize(CGSize(width: fullWidth, height: Constants.DefaultCellHeight), withHorizontalFittingPriority: UILayoutPriorityDefaultHigh, verticalFittingPriority: UILayoutPriorityDefaultLow)
            return size
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
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillTerminateNotification, object: nil, queue: nil) { [unowned self] notification in
            if TutorialManager.sharedInstance.completed {
                self.removeAllExeptLessons()
                APIManager.sharedInstance.clearHistory(nil)
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] notification in
            self.enteredToBackground()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: nil) { [unowned self] notification in
            self.senseiTapView.userInteractionEnabled = false
            self.previousApplicationState = .Inactive
            if let hidden = self.tutorialViewController?.splashMaskImageView.hidden where hidden == true {
                self.dismissViewController()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [unowned self] notification in
            if self.previousApplicationState != .Inactive {
                self.appOpenedFromTray()
            }
            
            self.enableSenseiInteractionIfNeeded()
            self.previousApplicationState = UIApplicationState.Active
        }

        NSNotificationCenter.defaultCenter().addObserverForName(ApplicationDidReceiveRemotePushNotification, object: nil, queue: nil) { [unowned self] notification in
            self.receivedPush()
            APIManager.sharedInstance.addToLog("Received push notfication")

            if let userInfo = notification.userInfo, push = PushNotification(userInfo: userInfo) {
                (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification = push
                self.processPushReceiving(push)
            }
        }
    }

    func enableSenseiInteractionIfNeeded() {
        if TutorialManager.sharedInstance.completed && !UpgradeManager.sharedInstance.isProVersion() || UpgradeManager.sharedInstance.isProVersion() && TutorialManager.sharedInstance.upgradeCompleted {
            self.senseiTapView.userInteractionEnabled = true
        }
    }

    func appLaunched() {
    
        SenseiManager.sharedManager.saveLastActiveTime()
        if SenseiManager.sharedManager.senseiSitting || (!TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.currentStep?.number < StepIndexes.MayIAskYourSexIndex.rawValue) {
            self.senseiImageView.image = SenseiManager.sharedManager.sittingImage()
        } else {
            self.senseiImageView.image = SenseiManager.sharedManager.standingImage()
        }
        self.senseiImageView.hidden = false
    }

    func appOpenedFromTray() {
        if let _ = self.parentViewController {
            SenseiManager.sharedManager.standBow = true
        }
    
        tutorialViewController?.splashMaskImageView.hidden = true //TUT
        if !self.startFromVis {
            self.showSitSenseiAnimation()
        } else {
            self.didBecomeActive()
        }
        SenseiManager.sharedManager.saveLastActiveTime()
        
        if let tabController = self.parentViewController as? SenseiTabController {
            tabController.maskBlack?.removeFromSuperview()
        }

        if let _ = (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification {
        } else {
            if TutorialManager.sharedInstance.completed {
                self.storeLastItem()
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
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

        if !APIManager.sharedInstance.reachability.isReachable() {
            addMessages([PlainMessage(text: "You’re currently not connected to the internet. All the information you just entered will be saved as soon as you reconnect.")], scroll: true, completion: nil)
        }
        
        dispatchInMainThreadAfter(delay: 2) {
            if TutorialManager.sharedInstance.completed {
                self.fetchLessons()
                (UIApplication.sharedApplication().delegate as! AppDelegate).registerForNotifications()
            }
        }
    }

    func didFinishUpgradeNotificatin(notification: NSNotification) {
        affirmationsButton.userInteractionEnabled = true
        visualisationsButton.userInteractionEnabled = true
        if SenseiManager.sharedManager.isSleepTime() {
            SenseiManager.sharedManager.animateSenseiSitDownInImageView(senseiImageView, completion: { (finished) in
                self.dispatchInMainThreadAfter(delay: 1) {
                    self.senseiTapView.userInteractionEnabled = true
                    self.performSegueWithIdentifier("ShowDisclaimer", sender: self)
                }
            })
        } else {
            dispatchInMainThreadAfter(delay: 1) {
                self.senseiTapView.userInteractionEnabled = true
                self.performSegueWithIdentifier("ShowDisclaimer", sender: self)
            }
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
                    if question is TutorialStep && (question as! TutorialStep).number == StepIndexes.WhatInYourNameIndex.rawValue {
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
        var delay = self.dataSource.count > 0 ? TutorialManager.sharedInstance.delayForCurrentStep() : 0
        if tutorialStep.number == 0 {
            delay = tutorialStep.delayBefore
        }
        if tutorialStep.number == StepIndexes.AfterThankYouIndex.rawValue || tutorialStep.number == 2  {
            delay = 1
        }

        dispatchInMainThreadAfter(delay: delay) {
            if let animatableimage = tutorialStep.animatableImage {

                if TutorialManager.sharedInstance.completed &&
                    SenseiManager.sharedManager.isSleepTime() &&
                    animatableimage.imageNames.first?.containsString("1_bow") == false &&
                    animatableimage.imageNames.first?.containsString("2_sistand") == false &&
                    tutorialStep.number > 37 && tutorialStep.number < 42 {
                    
                    SenseiManager.sharedManager.animateSenseiSittingInImageView(self.senseiImageView, completion: { (finished) in
                        self.animateTutorialStep(tutorialStep)
                    })
                } else {
                    let delay: Float = TutorialManager.sharedInstance.completed ? 1 : 0.2
                    self.dispatchInMainThreadAfter(delay: delay, completion: {
                        self.animateTutorialStep(tutorialStep)
                    })
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
    
    func animateTutorialStep(tutorialStep: TutorialStep) {
        if let animatableimage = tutorialStep.animatableImage {
            print(NSDate())
            self.senseiImageView.animateAnimatableImage(animatableimage) { (finished) -> Void in
                print(NSDate())
                self.senseiImageView.image = animatableimage.images.last
                self.handleTutorialStepAction(tutorialStep)
            }
        }
    }
    
    private func handleTutorialStepAction(tutorialStep: TutorialStep) {
        if !tutorialStep.text.isEmpty {
            self.addMessages([tutorialStep], scroll: true, completion: nil)
        }

        if TutorialManager.sharedInstance.completed && !UpgradeManager.sharedInstance.isProVersion() || TutorialManager.sharedInstance.upgradeCompleted && UpgradeManager.sharedInstance.isProVersion() {
            senseiTapView.userInteractionEnabled = true
            if !UpgradeManager.sharedInstance.isProVersion() && SenseiManager.sharedManager.isSleepTime() {
                sitDownSensei()
            }
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
        var delay: Float = 0.0
        if let names = controlNames where names.contains(ControlNames.AffirmationsButton) {
            delay = 2.0
        }
        self.dispatchInMainThreadAfter(delay: delay) {
            self.affirmationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.AffirmationsButton) ?? true
            self.visualisationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.VisualisationsButton) ?? true
        }
    }
}

// MARK: - Launch options

extension SenseiViewController {
    
    func receivedPush() {
        print("*** PUSH RECEIVED")
        
    }
    
    func enteredToBackground() {
        (UIApplication.sharedApplication().delegate as! AppDelegate).pushNotification = nil
        if TutorialManager.sharedInstance.completed {
            APIManager.sharedInstance.clearHistory { (error) in
                if error == nil {
                    self.removeAllExeptLessons()
                }
            }
        }
        previousApplicationState = UIApplicationState.Background
        lastAffirmation = nil
        lastVisualisation = nil
        invalidateTimer(standUpTimer)
        invalidateTimer(sitDownTimer)
    }
    
    
    func invalidateTimer(timer: NSTimer?) {
        var timer = timer
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func viewWillAppearCalled() {
        if !APIManager.sharedInstance.logined {
            view.setNeedsDisplay()
            view.setNeedsUpdateConstraints()
            
            if TutorialManager.sharedInstance.completed {
                fetchLessons()
            } else {
                login()
            }
        }
    }
    
    func didEnterBackground() {
        if TutorialManager.sharedInstance.completed {
            senseiImageView.hidden = true
        }
        senseiBottomSpaceConstraint.constant = Constants.DefaultBottomSpace
        transparrencyGradientLayer.startPoint = CGPointZero
        view.layoutIfNeeded()
        (view as? AnswerableView)?.resignFirstResponder()
        view.endEditing(true)
    }
    
    func didBecomeActive() {
        SenseiManager.sharedManager = SenseiManager()

        if SenseiManager.sharedManager.senseiSitting || (!TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.currentStep?.number < StepIndexes.MayIAskYourSexIndex.rawValue) {
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
        storeLastItem()
        
        if let _ = parentViewController where push.type == PushType.Visualisation {
            if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                self.showVisualisation(visualisation)
            }
        }
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] (error) -> Void in
            self.addLessonFromPush(push)
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
        self.storeLastItem()

        if push.type == PushType.Visualisation {
            if let visualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                self.showVisualisation(visualisation)
            }
        }
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] error in
            self.addLessonFromPush(push)
            switch push.type {
                case .Lesson:
                    let index = self.dataSource.find {
                        let idsEqual = ($0.id == push.id)
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
        guard let pushDate = push.date where push.type != .Visualisation else { return }
        
        storeLastItem()
        if let _ = CoreDataManager.sharedInstance.fetchObjectsWithEntityName("Lesson", sortDescriptors: [], predicate: NSPredicate(format: "date == %@", pushDate))?.first {
            return
        }
        removeAllExeptLessons()

        let message = PlainMessage(text: "")
        
        switch push.type {
        case .Lesson:
            message.text = push.alert
        case .Affirmation:
            var lessonMessage = push.alert.stringByReplacingOccurrencesOfString(push.preMessage, withString:"")
            lessonMessage = lessonMessage.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            message.text = "\(push.preMessage) \(lessonMessage)"
        default:
            break
        }
        message.date = pushDate
        insertMessage(message)
    }
    
    @IBAction func affirmationButtonTapped(sender: AnyObject) {
        SoundController.playTock()
        removeAllExeptLessons()
        APIManager.sharedInstance.clearHistory(nil)
    }
    
    @IBAction func visualisationButtonTapped(sender: AnyObject) {
        SoundController.playTock()
        removeAllExeptLessons()
        APIManager.sharedInstance.clearHistory(nil)
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
        
        if let lesson = message as? Lesson where (message as! Lesson).isTypeVisualization() {
            cell.visualization = Visualization.visualizationWithNumber(NSNumber(integer: (lesson.itemId as NSString).integerValue))
        }
        cell.attributedText = attributedCellTextAtIndexPath(indexPath)
        cell.showCloseButton(false)
        configureTipForCell(cell)

        return cell
    }
    
    func removeExpiredMessages() {
        for message in dataSource {
            if abs(message.date.timeIntervalSinceNow) > 3*60*60 {
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
        if message is PlainMessage {
            messageBody = NSMutableAttributedString(string: (message as! PlainMessage).text, attributes:  nil)
        }
//        let attrDate = NSAttributedString(string: "\n\n\(message.date)")
//        messageBody.appendAttributedString(attrDate)

        messageBody.addAttribute(NSFontAttributeName, value: UIFont.speechBubbleTextFont, range: NSMakeRange(0, messageBody.length))
        return messageBody
    }
}

// MARK: - UIScrollViewDelegate

extension SenseiViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        tutorialViewController?.splashMaskImageView.hidden = true  //Ne tut
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
//        tutorialViewController?.splashMaskImageView.hidden = true;  //Ne tut
    }
    
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
		return CGSize(width: min(width, CGRectGetWidth(collectionView.frame) - collectionView.contentInset.right), height: height)
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
                        if let gender = Gender(rawValue: answerMessage.text.capitalizedString) {
                            Settings.sharedSettings.gender = gender
                            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
                        }
                    default:
                        break
                }
            }
            TutorialManager.sharedInstance.nextStep()
        }
    }
    
    func answerableViewDidCancel(answerableView: AnswerableView) {
        if let question = self.lastQuestion where question.questionSubject == .Gender {
            TutorialManager.sharedInstance.skipStep()
        }
        TutorialManager.sharedInstance.nextStep()
    }
}

// MARK: - TextImagePreviewControllerDelegate

extension SenseiViewController: TextImagePreviewControllerDelegate {
    
    func textImagePreviewControllerWillDismiss() {
        if self.startFromVis == true {
            self.startFromVis = false
            print("LINE 1407")
            showSitSenseiAnimation()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension SenseiViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
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
        
        removeDuplicated()
        var animated = true
        if let tutorial = tutorialViewController where tutorial.splashMaskImageView.hidden {
            animated = true
            shouldReload = true
        }
        if tutorialViewController == nil {
            animated = false
        }
        if let tutorial = tutorialViewController where !tutorial.splashMaskImageView.hidden {
            reloadSectionAnimated(false, scroll: true, scrollAnimated: false)
        } else {
            reloadSectionAnimated(shouldReload, scroll: shouldReload, scrollAnimated: animated)
        }

        shouldReload = false
        reloadAnimated = false
    }
    
    func hideSplashImage() {
        if let tutorial = tutorialViewController where tutorial.splashMaskImageView.hidden {
            print("LINE 1475")
            self.showSitSenseiAnimation()
        }
        tutorialViewController?.splashMaskImageView.hidden = true
    }
}
