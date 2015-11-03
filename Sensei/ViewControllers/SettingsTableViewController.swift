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
    
    private let SaveConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to save this changes?")
    
    private var sleepTimeSettings: SleepTimeSettings?
    
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
        return picker
    }()
    
    private lazy var pickerInputAccessoryView: PickerInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.view.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = PickerInputAccessoryView(frame: rect)
        inputAccessoryView.rightButton.setTitle("Submit", forState: UIControlState.Normal)
        inputAccessoryView.leftButton.hidden = true
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            self?.view.endEditing(true)
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

        let genderEqual = (Settings.sharedSettings.gender == (maleButton.selected ? .Male: .Female))
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSettings()
        setup()
        addObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        fillFromSettings()
        (parentViewController as? SenseiTabController)?.delegate = self
        if !TutorialManager.sharedInstance.completed {
            TutorialManager.sharedInstance.nextStep()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        Settings.sharedSettings.gender = maleButton.selected ? .Male: .Female
        Settings.sharedSettings.height = heightCm > 0 ? NSNumber(double: heightCm): nil
        Settings.sharedSettings.weight = weightKg > 0 ? NSNumber(double: weightKg): nil
    }
    
    private func updateSettings() {
        APIManager.sharedInstance.updateSettingsWithCompletion({ [weak self] (settings, error) -> Void in
            self?.fillFromSettings()
            print("After \(Settings.sharedSettings)")
        })
    }
    
    private func fillFromSettings() {
        numberOfLessonsSlider.setCurrentValue(Settings.sharedSettings.numberOfLessons.integerValue, animated: false)
        tutorialSwitch.on = Settings.sharedSettings.tutorialOn.boolValue
        sleepTimeSettings = SleepTimeSettings(weekdaysStart: Settings.sharedSettings.sleepTimeWeekdays.start, weekdaysEnd: Settings.sharedSettings.sleepTimeWeekdays.end, weekendsStart: Settings.sharedSettings.sleepTimeWeekends.start, weekendsEnd: Settings.sharedSettings.sleepTimeWeekends.end)
        updateSleepTimeSettingTextFields()
        if let date = Settings.sharedSettings.dayOfBirth {
            dateOfBirthTF.text = DataFormatter.stringFromDate(date)
            datePicker.setDate(date, animated: false)
        } else {
            dateOfBirthTF.text = ""
        }
        
        if let height = Settings.sharedSettings.height where height.doubleValue > 0 {
            heightCm = height.doubleValue
        } else {
            heightTextField.text = ""
        }
        
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
            case .Male : selectGender(maleButton)
            case .Female: selectGender(femaleButton)
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
        (parentViewController as? SenseiTabController)?.showSenseiViewController()
    }
    
    func handleNoAnswerNotification(notification: NSNotification) {
        if hasSettingsBeenChanged {
            saveSettings()
        }
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
    }
    
    func handleYesAnswerNotification(notification: NSNotification) {
        if hasSettingsBeenChanged {
            saveSettings()
        }
        saveProfile()
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func toggleTutorial(sender: UISwitch) {
        Settings.sharedSettings.tutorialOn = NSNumber(bool: tutorialSwitch.on)
        if let tutorialViewController = tutorialViewController {
            if sender.on {
                tutorialViewController.showTutorialAnimated(true)
            } else {
                tutorialViewController.hideTutorialAnimated(true)
            }
        }
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
        }
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
        maleButton.selected = (sender == maleButton)
        femaleButton.selected = (sender == femaleButton)
    }
    
    @IBAction func shareOnFaebook() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
            let social = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            //TODO: Add social share text
            social.setInitialText("inital text")
            social.addURL(NSURL(string: "http://apple.com"))
            social.addImage(UIImage(named: "AppIcon"))
        } else {
            let alertController = UIAlertController(title: "Facebook unavailable", message: "Please enter you login and password in Settings.app", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (UIAlertAction) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(settingsURL)
                    }
                })
                
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (UIAlertAction) -> Void in
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)

        }
    }
    
    @IBAction func tweet() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            let social = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            //TODO: Add social share text
            social.setInitialText("inital text")
            social.addURL(NSURL(string: "http://apple.com"))
            social.addImage(UIImage(named: "AppIcon"))
        } else {
            let alertController = UIAlertController(title: "Twitter unavailable", message: "Please enter you login and password in Settings.app", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (UIAlertAction) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(settingsURL)
                    }
                })
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (UIAlertAction) -> Void in
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func rateInAppStore() {
        
    }
    
    /**
     Show the MFMailViewController to compose feedback message. 
     Recipient should be set to 'sensei@vigosensei.com'
     */
    @IBAction func giveFeedback() {
        if MFMailComposeViewController.canSendMail() {
            
            let mailComposeController = MFMailComposeViewController()
            mailComposeController.mailComposeDelegate = self
            mailComposeController.setToRecipients(["sensei@vigosensei.com"])
            mailComposeController.setSubject("Feedback")
            
            self.presentViewController(mailComposeController, animated: true, completion: nil)
            
        } else {
            AlertMessagesService.showWarningAlert(nil, message: "Can't send e-mail.", fromController: self, completion: nil)
        }
    }
    
    @IBAction func upgrade() {
        
    }
}

// MARK: - UITextFieldDelegate

extension SettingsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        firstResponder = textField
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
        if hasProfileBeenChanged {
            tutorialViewController?.askConfirmationQuestion(SaveConfirmationQuestion)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("tutorialDidHideNotification:"), name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
            return false
        } else if hasSettingsBeenChanged {
            saveSettings()
            APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
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
