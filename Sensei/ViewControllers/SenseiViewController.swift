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
//        static let CollectionContentInset = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 76)
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

	private lazy var transparrencyGradientLayer: CAGradientLayer = {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [UIColor(white: 0.0, alpha: 1.0).CGColor, UIColor(white: 0.0, alpha: 0.0).CGColor]
        /*
        Changed relative to https://trello.com/c/CSYHKBXF/28-sensei-screen-please-move-transparent-gradient-start-up-3h, was - gradientLayer.locations = [CGFloat(0.0), CGFloat(1.0)]
        */
		gradientLayer.locations = [CGFloat(0.0), CGFloat(0.5)]
        
		gradientLayer.startPoint = CGPointZero
		gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.6)
		return gradientLayer
	}()
    
    private lazy var shouldReload: Bool = false
    
    private lazy var sizingCell: SpeechBubbleCollectionViewCell = {
        NSBundle.mainBundle().loadNibNamed(RightSpeechBubbleCollectionViewCellNibName, owner: self, options: nil).first as! SpeechBubbleCollectionViewCell
    }()
    
    private var bottomContentInset: CGFloat {
        return senseiImageView.frame.size.height/128.0*100
    }
    
    private var collectionViewContentInset: UIEdgeInsets {
        let screenHeight = UIScreen.mainScreen().bounds.size.height

        var rightInset: CGFloat = 0
        
        switch (screenHeight) {
            case 568: rightInset = 70.0
            case 667: rightInset = 80.0
            case 736: rightInset = 90.0
            default: rightInset = 60.0
        }
        
//this hardcoded values were caused by the different sensei size for every iPhone resolution.. 
//Apple God blessed me for this shit
        
//iphone 4s == 60
//iphone 5s == 70
//iphone 6s == 80
//iphone 6sPlus == 90
        
        return UIEdgeInsets(top: 0, left: 11.0, bottom: 0, right: rightInset)
    }
    
    private var topContentInset: CGFloat {
        var top = CGRectGetMinY(senseiImageView.frame)
        if dataSource.count > 0 {
            let height = caluclateSizeForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)).height
            top = collectionView.frame.size.height - bottomContentInset - height
        }
        return top
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
    private var lastQuestion: QuestionProtocol?
    private var lastAffirmation: Affirmation?
    private var lastVisualisation: Visualization?
    
    
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
        
        if TutorialManager.sharedInstance.upgradeCompleted {
            fetchLessons()
        } else {
            login()
        }
        
        addApplicationObservers()
        addSenseiGesture()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialDidHideNotification:"), name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishTutorialNotificatin:"), name: TutorialManager.Notifications.DidFinishTutorial, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didFinishUpgradeNotificatin:"), name: TutorialManager.Notifications.DidFinishUpgrade, object: nil)
    }
    
    func setSitSensei(notification: NSNotification) {
        showSitSenseiAnimation()
    }
    
    func showSitSenseiAnimation() {
        if !TutorialManager.sharedInstance.completed && TutorialManager.sharedInstance.lastStepNumber() < 1 {
            senseiImageView.image = UIImage(named: "1_bow_0064")
        } else {
            if (UIApplication.sharedApplication().delegate as! AppDelegate).shouldSit {
                (UIApplication.sharedApplication().delegate as! AppDelegate).shouldSit = false
                senseiImageView.image = UIImage(named: "1_bow_0064")
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(1) * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.senseiImageView.animateAnimatableImage(AnimationManager.sharedManager.sitsBowAnimatableImage()!, completion: { (finished) -> Void in
                        self.senseiImageView.animateAnimatableImage(AnimationManager.sharedManager.sitStandAnimatableImage()!, completion: nil)
                    })
                }
            } else {
                senseiImageView.image = UIImage(named: "VigoSensei")
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tutorialViewController?.tutorialHidden = true
        collectionView.contentInset = collectionViewContentInset
        collectionView.contentInset.bottom = collectionViewBottomContentInset

        if APIManager.sharedInstance.logined && TutorialManager.sharedInstance.upgradeCompleted {
            APIManager.sharedInstance.lessonsHistoryCompletion(nil)
        }
        
        showSitSenseiAnimation()
        
        addKeyboardObservers()
        addTutorialObservers()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("setSitSensei:"), name: "SitSenseiNotification", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showLastReceivedVisualisation()
        let isPro = Settings.sharedSettings.isProVersion?.boolValue == true
        let isProCompleted = TutorialManager.sharedInstance.upgradeCompleted
        
        if !TutorialManager.sharedInstance.completed {
            if let _ = TutorialManager.sharedInstance.lastCompletedStepNumber {
                dispatchTutorialToAppropriateViewController()
            } else {
                TutorialManager.sharedInstance.nextStep()
            }
        } else if isPro && !isProCompleted {
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
//        if TutorialManager.sharedInstance.completed {
            removeAllExeptLessons()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		transparrencyGradientLayer.frame = fadingImageView.bounds
        collectionView.contentInset.top = topContentInset
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
            self.dataSource += lessons.map { $0 as Message }
            self.reloadSectionAnimated(true)
        }
        self.login()
    }
    
    private func insertMessage(message: Message, scroll: Bool) {
        var inserIndex: Int? = nil
        if dataSource.count > 1 {
            dataSource.append(message)
            dataSource = dataSource.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending})
            let id = message.id
            for index in 0..<(dataSource.count) {
                if dataSource[index].id == id {
                    inserIndex = index
                }
            }
        }
        if let inserIndex = inserIndex {
            let indexPath = NSIndexPath(forItem: inserIndex, inSection: 0)
            collectionView.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
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
        self.collectionView.contentInset.bottom = self.collectionViewBottomContentInset
        self.collectionView.contentInset.top = self.topContentInset
        collectionView.performBatchUpdates({ [unowned self] () -> Void in
//            self.collectionView.reloadSections(NSIndexSet(index: 0))
            self.collectionView.insertItemsAtIndexPaths(indexPathes)
        }, completion: { [unowned self] (finished) -> Void in
            if scroll {
                self.scrollToLastNotUsersItemAnimated(true)
            }
            if let completion = completion {
                self.configureBubles()
                completion()
            }
        })
    }
    
    func addMsesage(message: Message) {
        addMessages([message], scroll: true, completion: nil)
    }
    
    private func deleteMessageAtIndexPath(indexPath: NSIndexPath) {
        let message = dataSource.removeAtIndex(indexPath.item)
        if let message = message as? Lesson {
            APIManager.sharedInstance.blockLessonWithId((message).lessonId, handler: nil)
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
        // TODO: - DELETE HARDCODED IDFA
    #if DEBUG
//		let idfa = "5666C71D-7FE6-42B9-962C-16B977B3C08F"
//		let idfa = "8161C71D-7FE6-42B9-912C-16B977B3C08F" // meine
        if NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") == nil {
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "AutoUUID")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String
//		let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
        
    #else
        if NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") == nil {
            NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: "AutoUUID")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        let idfa = NSUserDefaults.standardUserDefaults().objectForKey("AutoUUID") as! String

//		let idfa = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString
    #endif
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
                } else {
                    APIManager.sharedInstance.lessonsHistoryCompletion(nil)
                }
            }
        }
    }
    
    private func askQuestion(question: QuestionProtocol) {
        lastQuestion = question
        let delay = self.dataSource.count > 0 ? (question as! QuestionTutorialStep).delayBefore : 0
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
            let collectionViewHeightWithoutBottomInset = CGRectGetHeight(collectionView.frame) - collectionViewBottomContentInset
            let offs = CGRectGetMaxY(attributes.frame) - collectionViewHeightWithoutBottomInset
            collectionView.contentInset.top = topContentInset
            collectionView.performBatchUpdates({ [unowned self]() -> Void in
                self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: offs), animated: animated)
            }, completion: { [unowned self] finished in
                self.configureBubles()
            })
        }
    }
    
    private func scrollToLastNotUsersItemAnimated(animated: Bool) {
        if let index = lastNotUserItemIndex {
            self.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), animated: animated)
        }
    }
    
    private func reloadSectionAnimated(animated: Bool) {
        if dataSource.count == 0 {
            return;
        }
        if animated {
            collectionView.performBatchUpdates({ [unowned self] in
                self.collectionView.reloadSections(NSIndexSet(index: 0))
            }, completion: { [unowned self] finished in
                self.collectionView.contentInset.top = self.topContentInset
                self.scrollToLastNotUsersItemAnimated(true)
            })
        } else {
            collectionView.reloadData()
            collectionView.contentInset.top = topContentInset
            scrollToLastNotUsersItemAnimated(false)
        }
    }

	private func caluclateSizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
		let fullWidth = collectionView.frame.size.width - collectionViewContentInset.left - collectionViewContentInset.right
		let message = dataSource[indexPath.item]
		sizingCell.text = (message is UserMessage) ? (message as! UserMessage).fullMessage() : message.text
		sizingCell.frame = CGRect(x: 0.0, y: 0.0, width: fullWidth, height: Constants.DefaultCellHeight)
		sizingCell.textView.layoutIfNeeded()
		if #available(iOS 9, *) {
			return sizingCell.systemLayoutSizeFittingSize(CGSize(width: fullWidth, height: Constants.DefaultCellHeight))
		} else  {
			let size = sizingCell.systemLayoutSizeFittingSize(CGSize(width: fullWidth, height: Constants.DefaultCellHeight), withHorizontalFittingPriority: 1000, verticalFittingPriority: 50)
			let textSize = SpeechBubbleCollectionViewCell.sizeForText(sizingCell.text, maxWidth: fullWidth, type: message is AnswerMessage ? .Me : .Sensei)
			print("Size \(size)")
			print("text size \(textSize)")
			return CGSize(width: min(size.width, textSize.width), height: size.height)
		}
	}

    // MARK: Sensei Gesture
    
    func addSenseiGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: "senseiTapped:")
        tapGesture.numberOfTapsRequired = 1
        senseiImageView.addGestureRecognizer(tapGesture)
    }
    
    func senseiTapped(recognizer: UITapGestureRecognizer) {
        if !senseiImageView.layerAnimating() && TutorialManager.sharedInstance.completed {
            senseiImageView.animateAnimatableImage(AnimationManager.sharedManager.bowsAnimatableImage()!, completion: nil)
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
    
    private func handleReceivedPushNotification(push: PushNotification) {
        switch push.type {
            case .Lesson:
                APIManager.sharedInstance.lessonsHistoryCompletion(nil)
                if !self.isTopViewController {
                    let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont, NSForegroundColorAttributeName: UIColor.blackColor()])
                    tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)
                }
            case .Affirmation:
                if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                    if let date = push.date {
                        affirmation.date = date
                    }
                    affirmation.preMessage = push.alert
                    self.lastAffirmation = affirmation

                    if !(self.navigationController?.topViewController is SenseiTabController) || ((parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                        let messageText = NSMutableAttributedString(string: affirmation.fullMessage(), attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                        tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)

                    } else if self.isTopViewController {
                        self.insertMessage(affirmation, scroll: self.isTopViewController)
                    }
                }
            case .Visualisation:
                self.lastVisualisation = Visualization.visualizationWithNumber(NSNumber(integer: (push.id as NSString).integerValue))
                self.lastVisualisation?.preMessage = push.alert

                if !(self.navigationController?.topViewController is SenseiTabController) || ((parentViewController as? SenseiTabController)?.currentViewController is SettingsTableViewController) {
                    let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                    messageText.addAttribute(NSLinkAttributeName, value: LinkToVisualization, range: NSMakeRange(0, messageText.length))
                    tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: true)

                } else if self.isTopViewController {
                    self.insertMessage(lastVisualisation!, scroll: self.isTopViewController)
                    self.refreshVisualizations()
                }
            }
    }
    
    func refreshVisualizations() {
        var indexPaths = Array<NSIndexPath>()
        
        for (index, element) in self.dataSource.enumerate() {
            if (element is Visualization) {
                indexPaths.append(NSIndexPath(forItem: index, inSection: 0))
            }
        }
        collectionView.reloadItemsAtIndexPaths(indexPaths)
    }
    
    override func affirmationTapped(notification: NSNotification) {

    }
    
    override func visualizationTapped(notification: NSNotification) {
        tutorialViewController?.hideTutorialAnimated(true)
        self.showLastReceivedVisualisation()
    }
    
    private func handleLaunchViaPush(push: PushNotification) {
        APIManager.sharedInstance.lessonsHistoryCompletion { [unowned self] error in
            switch push.type {
                case .Lesson:
                    let index = self.dataSource.find {
                        let idsEqual = $0.id == push.id
                        if let pushDate = push.date {
                            print("\(pushDate.timeIntervalSince1970) \($0.date.timeIntervalSince1970)")
                            print("\($0)")
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
                        affirmation.preMessage = push.alert
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
            self.refreshVisualizations()
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            self.affirmationsButton.userInteractionEnabled = true
            self.visualisationsButton.userInteractionEnabled = true
            if TutorialManager.sharedInstance.completed {
                (UIApplication.sharedApplication().delegate as! AppDelegate).registerForNotifications()
            }
        }
    }
    
    func didFinishUpgradeNotificatin(notification: NSNotification) {
        fetchLessons()
        affirmationsButton.userInteractionEnabled = true
        visualisationsButton.userInteractionEnabled = true
    }
    
    override func didMoveToNextTutorial(tutorialStep: TutorialStep) {
        super.didMoveToNextTutorial(tutorialStep)
        if tutorialStep.screen != .Sensei {
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
    
    private func handleTutorialStep(tutorialStep: TutorialStep) {
        let delay = tutorialStep.delayBefore
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
        if TutorialManager.sharedInstance.completed {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
                self.affirmationsButton.userInteractionEnabled = true
                self.visualisationsButton.userInteractionEnabled = true
            }
            return
        }
        affirmationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.AffirmationsButton) ?? true
        visualisationsButton.userInteractionEnabled = controlNames?.contains(ControlNames.VisualisationsButton) ?? true
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
        
        var mesageBody: NSMutableAttributedString;
        if let lastOne = lastVisualisation, let visualization = message as? Visualization {
            if visualization == lastOne {
                mesageBody = NSMutableAttributedString(string: visualization.fullMessage(), attributes: [NSLinkAttributeName: LinkToVisualization])
            } else {
                let text = (message is UserMessage) ? (message as! UserMessage).fullMessage() : message.text
                mesageBody = NSMutableAttributedString(string: text)
            }
        } else {
            let text = (message is UserMessage) ? (message as! UserMessage).fullMessage() : message.text
            mesageBody = NSMutableAttributedString(string: text)
        }
        
        mesageBody.addAttribute(NSFontAttributeName, value: UIFont.speechBubbleTextFont, range: NSMakeRange(0, mesageBody.length))
        cell.attributedText = mesageBody
        cell.showCloseButton(message is Lesson)
		let size = caluclateSizeForItemAtIndexPath(indexPath)
		let width = CGRectGetWidth(UIEdgeInsetsInsetRect(collectionView.bounds, collectionViewContentInset))
        cell.speachBubleOffset = width - size.width
        configureTipForCell(cell)
        return cell
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
        let frameToIntersect = CGRectMake(0, CGRectGetMinY(senseiImageView.frame) - 22.0, CGRectGetWidth(view.frame), CGRectGetHeight(senseiImageView.frame)/4)
        let cellFrameInView = collectionView.convertRect(cell.frame, toView: view)
        cell.speechBubbleView.showBubbleTip = CGRectIntersectsRect(cellFrameInView, frameToIntersect)
        print(cellFrameInView)
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
        shouldReload = true
        if let lesson = anObject as? Lesson {
            switch type {
                case .Delete:
                    dataSource = dataSource.filter() {
                        if $0 is Lesson {
                            return ($0 as! Lesson).date != lesson.date
                        }
                        return true
                    }
//                    collectionView.contentInset.top = topContentInset
                    shouldReload = false
                    print("Deleted \(lesson.date)")
                case .Insert:
                    dataSource.append(lesson as Message)
                    collectionView.contentInset.top = topContentInset
                    print("Inserted \(lesson.date)")
                    break
                default:
                    break
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldReload {
            dataSource.sortInPlace { $0.date.compare($1.date) == .OrderedAscending }
            reloadSectionAnimated(isTopViewController)
            print("Reload")
        }
    }
}
