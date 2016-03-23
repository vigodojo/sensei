//
//  SettingsTableViewController.swift
//  Sensei
//
//  Created by Dmitry Kanivets on 29.05.15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit
import Social
import MessageUI

enum FieldName: String {
    case DOB = "date of birth"
    case Weight = "weight"
    case Height = "height"
    case Sex = "sex"
}

enum CellHeight: CGFloat {
    case TeachingIntencityHeight = 94.0
    case InstructionSwitchHeight = 65.0
    case ShareUpgradeSleepTimeHeightPro = 370.0
    case ShareUpgradeSleepTimeHeightReg = 416.0
    case DateFormatHeight = 66.0
    case PersonalProfileHeight = 262.0
}

class SettingsTableViewController: UITableViewController {
    
    private struct Constants {
        static let ScrollToTopTutorialStepNumber = 24
    }
    
    private struct SleepTimeSettings {
        var weekdaysStart: NSDate!
        var weekdaysEnd: NSDate!
        var weekendsStart: NSDate!
        var weekendsEnd: NSDate!
    }
    
    @IBOutlet var settingsTableView: UITableView!
    
    @IBOutlet weak var numberOfLessonsSlider: VigoSlider!
    @IBOutlet weak var tutorialSwitch: UISwitch!
    @IBOutlet weak var weekDaysStartTF: UITextField!
    @IBOutlet weak var weekDaysEndTF: UITextField!
    @IBOutlet weak var weekEndsStartTF: UITextField!
    @IBOutlet weak var weekEndsEndTF: UITextField!
    @IBOutlet weak var dateOfBirthTF: UITextField!
    @IBOutlet weak var weightTexField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var usDataFormatButton: UIButton!
    @IBOutlet weak var metricDataFormatButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var shareOnFacebookButton: UIButton!
    @IBOutlet weak var tweetButton: UIButton!
    @IBOutlet weak var rateInAppStoreButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var upgradeSeparatorView: UIView!
    @IBOutlet weak var upgradeViewHeightConstraint: NSLayoutConstraint!
    
    private let SaveConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to save this changes?")
    
    func confirmationTextWithPropertyName(property: FieldName) -> ConfirmationQuestion {
        return ConfirmationQuestion(text: "Are you sure you want to change \(property.rawValue)?")
    }
    
    private var sleepTimeSettings: SleepTimeSettings?
    
    private var fieldToChange: FieldName?
    
    private lazy var timePicker: UIDatePicker = { [unowned self] in
        let picker = UIDatePicker()
        picker.datePickerMode = .Time
        picker.addTarget(self, action: Selector("timePickerDidChangeValue:"), forControlEvents: UIControlEvents.ValueChanged)
		picker.backgroundColor = UIColor.whiteColor()
        return picker
    }()
    
    private lazy var datePicker: UIDatePicker = { [unowned self] in
        let picker = UIDatePicker()
        picker.datePickerMode = .Date
        picker.addTarget(self, action: Selector("datePickerDidChangeValue:"), forControlEvents: UIControlEvents.ValueChanged)
		picker.backgroundColor = UIColor.whiteColor()
        
        let minComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Era], fromDate: NSDate())
        minComponents.year -= 100
        picker.minimumDate = NSCalendar.currentCalendar().dateFromComponents(minComponents)
        
        let maxComponents = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Era], fromDate: NSDate())
        maxComponents.year -= 10
        picker.maximumDate = NSCalendar.currentCalendar().dateFromComponents(maxComponents)

        return picker
    }()
    
    private lazy var pickerInputAccessoryView: PickerInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.view.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = PickerInputAccessoryView(frame: rect)
        inputAccessoryView.rightButton.setTitle("Submit", forState: UIControlState.Normal)
        inputAccessoryView.leftButton.hidden = true
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            self?.view.endEditing(true)
        
            if let fieldName = self?.fieldToChange {
                if fieldName == .DOB {
                    self?.dateOfBirthTF.text = DataFormatter.stringFromDate((self?.datePicker.date)!)
                }
                
                if fieldName == .Height {
                    let pickerDelegate = self?.heightPickerDelegate
                    let currentValue = pickerDelegate?.currentValueForPickerView((self?.heightPicker)!)
                    self?.heightCm = currentValue!.realValue
                    self?.heightTextField.text = "\(currentValue!)"
                }
                
                if fieldName == .Weight {
                    let pickerDelegate = self?.weightPickerDelegate
                    let currentValue = pickerDelegate?.currentValueForPickerView((self?.weightPicker)!)
                    self?.weightKg = currentValue!.realValue
                    self?.weightTexField.text = "\(currentValue!)"
                }
                
                print("\(Settings.sharedSettings.weight?.doubleValue) | \(self?.weightKg)")
                print("\(Settings.sharedSettings.height?.doubleValue) | \(self?.heightCm)")

                if (Settings.sharedSettings.weight?.doubleValue != self?.weightKg && Settings.sharedSettings.weight?.doubleValue > 0 && self?.weightKg > 0 ||
                    Settings.sharedSettings.height?.doubleValue != self?.heightCm && Settings.sharedSettings.height?.doubleValue > 0 && self?.heightCm > 0 ||
                    Settings.sharedSettings.dayOfBirth?.compare((self?.datePicker.date)!) != NSComparisonResult.OrderedSame && Settings.sharedSettings.dayOfBirth != nil) {
                        
                    self?.showConfirmation(self!.confirmationTextWithPropertyName(fieldName))
                } else {
                    self?.performYesAnswerAction()
                }
            }
        }
        return inputAccessoryView
    }()
    
    private lazy var heightPickerDelegate: HeightPickerDelegate = { [unowned self] in
        let pickerDelegate = HeightPickerDelegate()
        pickerDelegate.didChangeValueEvent = { [weak self] (newHeight: Length) -> Void in
            self?.heightCm = newHeight.realValue
            self?.heightTextField.text = "\(newHeight)"
        }

        return pickerDelegate
    }()
    
    private lazy var weightPickerDelegate: WeightPickerDelegate = { [unowned self] in
        let pickerDelegate = WeightPickerDelegate()
        pickerDelegate.didChangeValueEvent = { [weak self] (newWeight: Mass) -> Void in
            self?.weightKg = newWeight.realValue
            self?.weightTexField.text = "\(newWeight)"
        }

        return pickerDelegate
    }()
    
    private lazy var heightPicker: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self.heightPickerDelegate
        picker.delegate = self.heightPickerDelegate
		picker.backgroundColor = UIColor.whiteColor()
        return picker
    }()
    
    private lazy var weightPicker: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self.weightPickerDelegate
        picker.delegate = self.weightPickerDelegate
		picker.backgroundColor = UIColor.whiteColor()
        return picker
    }()
    
    private weak var firstResponder: UITextField?
    
    private var dataFormat = DataFormat.US {
        didSet {
            heightPicker.reloadAllComponents()
            weightPicker.reloadAllComponents()
            switch dataFormat {
                case .US:
                    if heightCm > 0 {
                        let heightUS = DataFormatter.centimetersToFeetAndInches(heightCm)
                        let feet = min(max(HeightPickerDelegate.Constants.MinHeightFt, heightUS.0), HeightPickerDelegate.Constants.MaxHeightFt)
                        let inches = min(max(HeightPickerDelegate.Constants.MinHeightIn, Int(round(heightUS.1))), HeightPickerDelegate.Constants.MaxHeightIn)
                        heightPicker.selectRow(feet - HeightPickerDelegate.Constants.MinHeightFt, inComponent: 0, animated: false)
                        heightPicker.selectRow(inches - HeightPickerDelegate.Constants.MinHeightIn, inComponent: 1, animated: false)
                        heightTextField.text = "\(feet)' \(inches)\""
                    }
                    
                    if weightKg > 0 {
                        let weightUS = min(max(WeightPickerDelegate.Constants.MinWeightLb, Int(round(DataFormatter.kilogramsToPounds(weightKg)))), WeightPickerDelegate.Constants.MaxWeightLb)
                        weightPicker.selectRow(weightUS - WeightPickerDelegate.Constants.MinWeightLb, inComponent: 0, animated: false)
                        weightTexField.text = "\(weightUS) " + Abbreviation.Pounds
                    }
                case .Metric:
                    if heightCm > 0 {
                        let height = min(max(HeightPickerDelegate.Constants.MinHeightCm, Int(round(heightCm))), HeightPickerDelegate.Constants.MaxHeightCm)
                        heightPicker.selectRow(height - HeightPickerDelegate.Constants.MinHeightCm, inComponent: 0, animated: false)
                        heightTextField.text = "\(Int(round(heightCm))) " + Abbreviation.Centimetres
                    }
                    
                    if weightKg > 0 {
                        let weight = min(max(WeightPickerDelegate.Constants.MinWeightKg, Int(round(weightKg))), WeightPickerDelegate.Constants.MaxWeightKg)
                        weightPicker.selectRow(weight - WeightPickerDelegate.Constants.MinWeightKg, inComponent: 0, animated: false)
                        weightTexField.text = "\(weight) " + Abbreviation.Kilograms
                    }
            }
            timePicker.locale = DataFormatter.locale
            datePicker.locale = DataFormatter.locale
            updateSleepTimeSettingTextFields()
            if Settings.sharedSettings.dayOfBirth != nil  {
                dateOfBirthTF.text = DataFormatter.stringFromDate(datePicker.date)
            }
        }
    }
    private var heightCm = Double(0)
    private var weightKg = Double(0)
    
    private var hasProfileBeenChanged: Bool {
        var dobEqual = false
        if let dob = Settings.sharedSettings.dayOfBirth {
            dobEqual = DataFormatter.stringFromDate(dob) == dateOfBirthTF.text
        } else {
            dobEqual = dateOfBirthTF.text!.isEmpty
        }

        let genderEqual = (Settings.sharedSettings.gender == (maleButton.selected ? .Male: .Female)) || (!maleButton.selected && !femaleButton.selected)
        
        var heightEqual = false
        if let height = Settings.sharedSettings.height {
            heightEqual = height.doubleValue == heightCm
        } else {
            heightEqual = true
        }
        var weightEqual = false
        if let weight = Settings.sharedSettings.weight {
            weightEqual = weight.doubleValue == weightKg
        } else {
            weightEqual = true;
        }
        return !dobEqual || !genderEqual || !heightEqual || !weightEqual
    }
    
    private var hasSettingsBeenChanged: Bool {
        let numberOfLessonsEqual = Settings.sharedSettings.numberOfLessons.integerValue == numberOfLessonsSlider.currentValue
        var timeSettingsEqual = false
        if let timeSettings = sleepTimeSettings {
            let weekdaysStartEqual = Settings.sharedSettings.sleepTimeWeekdays.start.compare(timeSettings.weekdaysStart) == .OrderedSame
            let weekdaysEndEqual = Settings.sharedSettings.sleepTimeWeekdays.end.compare(timeSettings.weekdaysEnd) == .OrderedSame
            let weekendsStartEqual = Settings.sharedSettings.sleepTimeWeekends.start.compare(timeSettings.weekendsStart) == .OrderedSame
            let weekendsEndEqual = Settings.sharedSettings.sleepTimeWeekends.end.compare(timeSettings.weekendsEnd) == .OrderedSame
            timeSettingsEqual = weekdaysStartEqual && weekdaysEndEqual && weekendsStartEqual && weekendsEndEqual
        }
        return !numberOfLessonsEqual || !timeSettingsEqual
    }
    
    private var previousApplicationState = UIApplicationState.Background

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if TutorialManager.sharedInstance.completed {
            updateSettings()
        }
        setup()
        addObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if TutorialManager.sharedInstance.completed {
            updateSettings()
        }
        CoreDataManager.sharedInstance.saveContext()
        refreshUpgradState()
        fillFromSettings()
        (parentViewController as? SenseiTabController)?.delegate = self
        if !TutorialManager.sharedInstance.completed {
            TutorialManager.sharedInstance.nextStep()
        }
        tutorialSwitch.enabled = TutorialManager.sharedInstance.completed
    }
    
    private func handleReceivedPushNotification(push: PushNotification) {
        if UIApplication.sharedApplication().applicationState == .Inactive && self.previousApplicationState == .Background {
            (self.navigationController?.viewControllers.first as? SenseiTabController)?.showSenseiViewController()
            return
        }
        switch push.type {
            case .Lesson:
                if let _ = parentViewController as? SenseiTabController {
                    let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont, NSForegroundColorAttributeName: UIColor.blackColor()])
                    tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: false)
                }
            case .Affirmation:
                if let affirmation = Affirmation.affirmationWithNumber(NSNumber(integer: (push.id as NSString).integerValue)) {
                    affirmation.preMessage = push.preMessage
                    
                    let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                    tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: true)
                }
            case .Visualisation:
                let messageText = NSMutableAttributedString(string: push.alert, attributes: [NSFontAttributeName: UIFont.speechBubbleTextFont])
                messageText.addAttribute(NSLinkAttributeName, value: LinkToVisualization, range: NSMakeRange(0, messageText.length))
                tutorialViewController?.showMessage(PlainMessage(attributedText: messageText), upgrade: true)
        }
    }
    
    
    func refreshUpgradState() {
        upgradeButton.enabled = !UpgradeManager.sharedInstance.isProVersion()
        upgradeViewHeightConstraint.constant = UpgradeManager.sharedInstance.isProVersion() ? 0.0 : 46.0
        upgradeSeparatorView.hidden = !UpgradeManager.sharedInstance.isProVersion()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)

        (parentViewController as? SenseiTabController)?.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
    }
  
    // MARK: - Private
    
    private func setup() {
        weekDaysStartTF.inputView = timePicker
        weekDaysStartTF.inputAccessoryView = pickerInputAccessoryView
        weekDaysEndTF.inputView = timePicker
        weekDaysEndTF.inputAccessoryView = pickerInputAccessoryView
        weekEndsStartTF.inputView = timePicker
        weekEndsStartTF.inputAccessoryView = pickerInputAccessoryView
        weekEndsEndTF.inputView = timePicker
        weekEndsEndTF.inputAccessoryView = pickerInputAccessoryView
        dateOfBirthTF.inputView = datePicker
        dateOfBirthTF.inputAccessoryView = pickerInputAccessoryView
        heightTextField.inputView = heightPicker
        heightTextField.inputAccessoryView = pickerInputAccessoryView
        weightTexField.inputView = weightPicker
        weightTexField.inputAccessoryView = pickerInputAccessoryView
    }
    
    private func addObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleNoAnswerNotification:"), name: TutorialBubbleCollectionViewCell.Notifications.NoAnswer, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleYesAnswerNotification:"), name: TutorialBubbleCollectionViewCell.Notifications.YesAnswer, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didMoveToNextTutorialNotification:"), name: TutorialManager.Notifications.DidMoveToNextStep, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didUpgradeToPro:"), name: UpgradeManager.Notifications.DidUpgrade, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] notification in
            self.previousApplicationState = UIApplicationState.Background
        }
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: nil) { [unowned self]notification in
            self.previousApplicationState = UIApplicationState.Active
        }
        NSNotificationCenter.defaultCenter().addObserverForName(ApplicationDidReceiveRemotePushNotification, object: nil, queue: nil) { [unowned self] notification in
            if let userInfo = notification.userInfo, push = PushNotification(userInfo: userInfo) {
                self.handleReceivedPushNotification(push)
            }
        }
        NSNotificationCenter.defaultCenter().addObserverForName(TutorialBubbleCollectionViewCell.Notifications.VisualizationTap, object: nil, queue: nil) { [unowned self] notification in
            if let _ = self.parentViewController as? SenseiTabController {
                self.tutorialViewController?.hideTutorialAnimated(true)
            }
        }
    }
    
    func didUpgradeToPro(notification: NSNotification) {
        if parentViewController is SenseiTabController {
            Settings.sharedSettings.isProVersion = NSNumber(bool: true)
            CoreDataManager.sharedInstance.saveContext()
            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
            let parent = parentViewController as! SenseiTabController
            parent.showSenseiViewController()
            refreshUpgradState()
        }
    }
    
    private func saveSettings() {
        Settings.sharedSettings.numberOfLessons = NSNumber(integer: numberOfLessonsSlider.currentValue)
        if let timeSettings = sleepTimeSettings {
            Settings.sharedSettings.sleepTimeWeekdays.start = timeSettings.weekdaysStart
            Settings.sharedSettings.sleepTimeWeekdays.end = timeSettings.weekdaysEnd
            Settings.sharedSettings.sleepTimeWeekends.start = timeSettings.weekendsStart
            Settings.sharedSettings.sleepTimeWeekends.end = timeSettings.weekendsEnd
        }
    }
    
    private func saveProfile() {
        Settings.sharedSettings.dayOfBirth = DataFormatter.dateFromString(dateOfBirthTF.text!)

        if !maleButton.selected && !femaleButton.selected {
            Settings.sharedSettings.gender = .SheMale
        } else {
            if maleButton.selected {
                Settings.sharedSettings.gender = .Male
            }
            if femaleButton.selected {
                Settings.sharedSettings.gender = .Female
            }
        }
        Settings.sharedSettings.height = heightCm > 0 ? NSNumber(double: heightCm): nil
        Settings.sharedSettings.weight = weightKg > 0 ? NSNumber(double: weightKg): nil
        CoreDataManager.sharedInstance.saveContext()
    }
    
    private func updateSettings() {
        fillFromSettings()
    }
    
    private func showConfirmation(question: ConfirmationQuestion) {
        tutorialViewController?.askConfirmationQuestion(question)
        fieldToChange = nil
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialDidHideNotification:"), name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
    }
    
    private func fillFromSettings() {
        numberOfLessonsSlider.setCurrentValue(Settings.sharedSettings.numberOfLessons.integerValue, animated: false)
        tutorialSwitch.on = Settings.sharedSettings.tutorialOn.boolValue
        sleepTimeSettings = SleepTimeSettings(weekdaysStart: Settings.sharedSettings.sleepTimeWeekdays.start, weekdaysEnd: Settings.sharedSettings.sleepTimeWeekdays.end, weekendsStart: Settings.sharedSettings.sleepTimeWeekends.start, weekendsEnd: Settings.sharedSettings.sleepTimeWeekends.end)
        
        updateSleepTimeSettingTextFields()
        configureTimeFieldsBorder()
        
        if let date = Settings.sharedSettings.dayOfBirth {
            dateOfBirthTF.text = DataFormatter.stringFromDate(date)
            datePicker.setDate(date, animated: false)
        } else {
            dateOfBirthTF.text = ""
        }
        
        heightCm = Double(0)
        if let height = Settings.sharedSettings.height where height.doubleValue > 0 {
            heightCm = height.doubleValue
        } else {
            heightTextField.text = ""
        }
        
        weightKg = Double(0)
        if let weight = Settings.sharedSettings.weight where weight.doubleValue > 0 {
            weightKg = weight.doubleValue
        } else {
            weightTexField.text = ""
        }
        
        switch Settings.sharedSettings.dataFormat {
            case .US : selectDataFormat(usDataFormatButton)
            case .Metric: selectDataFormat(metricDataFormatButton)
        }
        
        switch Settings.sharedSettings.gender {
            case .Male : configureGenderSelection(maleButton)
            case .Female: configureGenderSelection(femaleButton)
            case .SheMale:
                self.maleButton.selected = false
                self.femaleButton.selected = false
        }
    }
    
    private func updateSleepTimeSettingTextFields() {
        if let timeSettings = sleepTimeSettings {
            weekDaysStartTF.text = DataFormatter.stringFromTime(timeSettings.weekdaysStart)
            weekDaysEndTF.text = DataFormatter.stringFromTime(timeSettings.weekdaysEnd)
            weekEndsStartTF.text = DataFormatter.stringFromTime(timeSettings.weekendsStart)
            weekEndsEndTF.text = DataFormatter.stringFromTime(timeSettings.weekendsEnd)
        }
    }
    
    // MARK: - Scrolling
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleContentOffsetChange(scrollView.contentOffset)
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        handleContentOffsetChange(scrollView.contentOffset)
    }
    
    private func handleContentOffsetChange(contentOffset: CGPoint) {
        if contentOffset.y == 0 {
            didScrollToTop()
        } else if contentOffset.y == (tableView.contentSize.height - CGRectGetHeight(tableView.frame)) {
            didScrollToBottom()
        }
    }
    
    private func didScrollToTop() {
        if !TutorialManager.sharedInstance.completed {
            if let allowedAction = TutorialManager.sharedInstance.currentStep?.allowedAction where allowedAction == .ScrollToTop {
                TutorialManager.sharedInstance.nextStep()
            }
        }
    }
    
    private func didScrollToBottom() {
        if !TutorialManager.sharedInstance.completed {
            if let allowedAction = TutorialManager.sharedInstance.currentStep?.allowedAction where allowedAction == .ScrollToBottom {
                TutorialManager.sharedInstance.nextStep()
            }
        }
    }
    
    // MARK: - Tutorial
    
    func didMoveToNextTutorialNotification(notification: NSNotification) {
        if let tutorialStep = notification.userInfo?[TutorialManager.UserInfoKeys.TutorialStep] as? TutorialStep {
            if tutorialStep.number == Constants.ScrollToTopTutorialStepNumber && tableView.contentOffset.y == 0 {
                TutorialManager.sharedInstance.nextStep()
            }
        }
    }

    // MARK: - Tutorial View
    
    func tutorialDidHideNotification(notification: NSNotification) {
        (parentViewController as? SenseiTabController)?.delegate = nil
    }
    
    func handleNoAnswerNotification(notification: NSNotification) {
        fillFromSettings()
    }
    
    func handleYesAnswerNotification(notification: NSNotification) {
        performYesAnswerAction()
    }
    
    func performYesAnswerAction() {
        if hasSettingsBeenChanged {
            saveSettings()
        }
        saveProfile()
    }
    
    // MARK: - IBActions
    
    @IBAction func toggleTutorial(sender: UISwitch) {
        Settings.sharedSettings.tutorialOn = NSNumber(bool: tutorialSwitch.on)
    }
    
    @IBAction func timePickerDidChangeValue(sender: UIDatePicker) {
        if let textField = firstResponder {
            textField.text = DataFormatter.stringFromTime(sender.date)
            if textField == weekDaysStartTF {
                sleepTimeSettings?.weekdaysStart = sender.date
            } else if textField == weekDaysEndTF {
                sleepTimeSettings?.weekdaysEnd = sender.date
            } else if textField == weekEndsStartTF {
                sleepTimeSettings?.weekendsStart = sender.date
            } else if textField == weekEndsEndTF {
                sleepTimeSettings?.weekendsEnd = sender.date
            }
            
            configureTimeFieldsBorder()
        }
    }
    
    func configureTimeFieldsBorder() {
        
        let weekSleepStart = sleepTimeSettings?.weekdaysStart
        let weekSleepEnd = sleepTimeSettings?.weekdaysEnd
        let weekendSleepStart = sleepTimeSettings?.weekendsStart
        let weekendSleepEnd = sleepTimeSettings?.weekendsEnd
        
        let weekComponents = NSCalendar.currentCalendar().components([.Hour, .Minute], fromDate: weekSleepEnd!)
        let nextWeekSleepEnd = NSCalendar.currentCalendar().nextDateAfterDate(weekSleepStart!, matchingComponents: weekComponents, options: .MatchNextTime)!
        
        let weekendComponents = NSCalendar.currentCalendar().components([.Hour, .Minute], fromDate: weekendSleepEnd!)
        let nextWeekendSleepEnd = NSCalendar.currentCalendar().nextDateAfterDate(weekendSleepStart!, matchingComponents: weekendComponents, options: .MatchNextTime)!
        
        let weekNonSleepTimeInterval = nextWeekSleepEnd.timeIntervalSinceDate(weekSleepStart!)
        let weekendNonSleepTimeInterval = nextWeekendSleepEnd.timeIntervalSinceDate(weekendSleepStart!)

        let twentyThreeAndHalf: Double = 0.5*60*60
        let twelveHours: Double = 12*60*60
        
        if weekNonSleepTimeInterval <= twelveHours && weekNonSleepTimeInterval >= twentyThreeAndHalf {
            setSenseiBorder(weekDaysStartTF)
            setSenseiBorder(weekDaysEndTF)
        } else {
            setRedBorder(weekDaysStartTF)
            setRedBorder(weekDaysEndTF)
        }
        
        if weekendNonSleepTimeInterval <= twelveHours && weekendNonSleepTimeInterval >= twentyThreeAndHalf {
            setSenseiBorder(weekEndsStartTF)
            setSenseiBorder(weekEndsEndTF)
        } else {
            setRedBorder(weekEndsStartTF)
            setRedBorder(weekEndsEndTF)
        }
    }
    
    func setSenseiBorder(view: UIView) {
        view.layer.borderColor = UIColor(red: 49/255.0, green: 93/255.0, blue: 127/255.0, alpha: 1.0).CGColor
        view.layer.borderWidth = 0.5
    }
    
    func setRedBorder(view: UIView) {
        view.layer.borderColor = UIColor.redColor().CGColor
        view.layer.borderWidth = 1
    }
    
    @IBAction func datePickerDidChangeValue(sender: UIDatePicker) {
        dateOfBirthTF.text = DataFormatter.stringFromDate(sender.date)
    }
    
    @IBAction func selectDataFormat(sender: UIButton) {
        usDataFormatButton.selected = (sender == usDataFormatButton)
        metricDataFormatButton.selected = (sender == metricDataFormatButton)
        Settings.sharedSettings.dataFormat = usDataFormatButton.selected ? .US: .Metric
        dataFormat = Settings.sharedSettings.dataFormat
    }
    
    @IBAction func selectGender(sender: UIButton) {
        if !((maleButton.selected && maleButton == sender) || (femaleButton.selected && femaleButton == sender)) {
            configureGenderSelection(sender)

            if Settings.sharedSettings.gender != .SheMale {
                fieldToChange = .Sex
                showConfirmation(confirmationTextWithPropertyName(fieldToChange!))
            } else {
                if maleButton.selected {
                    Settings.sharedSettings.gender = .Male
                }
                if femaleButton.selected {
                    Settings.sharedSettings.gender = .Female
                }
            }
        }
    }
    
    private func configureGenderSelection(sender: UIButton) {
        maleButton.selected = (sender == maleButton)
        femaleButton.selected = (sender == femaleButton)
    }
    
    @IBAction func shareOnFaebook() {
        if !TutorialManager.sharedInstance.completed {
            return
        }
        SocialPostingService.postToSocialNetworksWithType(.Facebook, fromController: self) { [unowned self] (composeResult) -> Void in
            self.sharedWithResult(composeResult)
        }
    }
    
    @IBAction func tweet() {
        if !TutorialManager.sharedInstance.completed {
            return
        }
        SocialPostingService.postToSocialNetworksWithType(.Twitter, fromController: self) { [unowned self] (composeResult) -> Void in
            self.sharedWithResult(composeResult)
        }
    }
    
    func sharedWithResult(result: SLComposeViewControllerResult) {
        if result == .Done {
            AlertsController.sharedController.setShareAlertDisplayed()
        }
    }
    
    @IBAction func rateInAppStore() {
        if !TutorialManager.sharedInstance.completed {
            return
        }
        UpgradeManager.sharedInstance.openAppStoreURL()
    }
    
    /**
     Show the MFMailViewController to compose feedback message. 
     Recipient should be set to 'sensei@vigosensei.com', 
     subject - 'Note from a user'
     */
    @IBAction func giveFeedback() {
        if !TutorialManager.sharedInstance.completed {
            return
        }
        if MFMailComposeViewController.canSendMail() {
            
            let mailComposeController = MFMailComposeViewController()
            mailComposeController.mailComposeDelegate = self
            mailComposeController.setToRecipients(["sensei@vigosensei.com"])
            mailComposeController.setSubject("Note from a user")
            
            self.presentViewController(mailComposeController, animated: true, completion: nil)
            
        } else {
            AlertMessagesService.showWarningAlert(nil, message: "Can't send e-mail.", fromController: self, completion: nil)
        }
    }
    
    @IBAction func upgrade() {
        if !TutorialManager.sharedInstance.completed {
            let alert = UIAlertView(title: "Alert", message: "You need to finish the tutorial first", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
            alert.show()
            return
        }
        UpgradeManager.sharedInstance.askForUpgrade()
//UpgradeManager.sharedInstance.openAppStoreURL 
    }
}

// MARK: - UITableViewDelegate

extension SettingsTableViewController {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.row) {
            case 0: return CellHeight.TeachingIntencityHeight.rawValue
            case 1: return CellHeight.InstructionSwitchHeight.rawValue
            case 2: return UpgradeManager.sharedInstance.isProVersion() ? CellHeight.ShareUpgradeSleepTimeHeightPro.rawValue : CellHeight.ShareUpgradeSleepTimeHeightReg.rawValue
            case 3: return CellHeight.DateFormatHeight.rawValue;
            case 4: return CellHeight.PersonalProfileHeight.rawValue
            default: return 0
        }
    }
}
// MARK: - UITextFieldDelegate

extension SettingsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        firstResponder = textField
        fieldToChange = nil
        if textField == dateOfBirthTF {
            fieldToChange = .DOB
        }
        if textField == heightTextField {
            fieldToChange = .Height
        }
        if textField == weightTexField {
            fieldToChange = .Weight
        }
        if textField.inputView == timePicker {
            if let date = DataFormatter.timeFromString(textField.text!) {
                timePicker.setDate(date, animated: false)
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        firstResponder = nil
    }
}

// MARK: - SenseiTabControllerDelegate

extension SettingsTableViewController: SenseiTabControllerDelegate {
    
    func senseiTabController(senseiTabController: SenseiTabController, shouldSelectViewController: UIViewController) -> Bool {
        if !TutorialManager.sharedInstance.completed {
            saveSettings()
            saveProfile()
            return true
        }
        if hasSettingsBeenChanged {
            saveSettings()
            print("before save \(Settings.sharedSettings)")
//            APIManager.sharedInstance.saveSettings(Settings.sharedSettings) { (error) -> Void in
//                print("after save \(Settings.sharedSettings)")
//            }
        }
        return true
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    
    /**
     Delegate method that will be called when we are done with MFMailComposeViewController, 
     it should be dismissed.
     */
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
