//
//  SettingsTableViewController.swift
//  Sensei
//
//  Created by Dmitry Kanivets on 29.05.15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
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
    
    private let SaveConfirmationQuestion = ConfirmationQuestion(text: "Are you sure you want to save this changes?")
    
    private var sleepTimeSettings: SleepTimeSettings?
    
    private lazy var timePicker: UIDatePicker = { [unowned self] in
        let picker = UIDatePicker()
        picker.datePickerMode = .Time
        picker.addTarget(self, action: Selector("timePickerDidChangeValue:"), forControlEvents: UIControlEvents.ValueChanged)
        return picker
    }()
    
    private lazy var datePicker: UIDatePicker = { [unowned self] in
        let picker = UIDatePicker()
        picker.datePickerMode = .Date
        picker.addTarget(self, action: Selector("datePickerDidChangeValue:"), forControlEvents: UIControlEvents.ValueChanged)
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
        return picker
    }()
    
    private lazy var weightPicker: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self.weightPickerDelegate
        picker.delegate = self.weightPickerDelegate
        return picker
    }()
    
    private weak var firstResponder: UITextField?
    
    private var dataFormat = DataFormat.US {
        didSet {
            heightPicker.reloadAllComponents()
            weightPicker.reloadAllComponents()
            switch dataFormat {
                case .US:
                    let heightUS = DataFormatter.centimetersToFeetAndInches(heightCm)
                    let feet = min(max(HeightPickerDelegate.Constants.MinHeightFt, heightUS.0), HeightPickerDelegate.Constants.MaxHeightFt)
                    let inches = min(max(HeightPickerDelegate.Constants.MinHeightIn, Int(round(heightUS.1))), HeightPickerDelegate.Constants.MaxHeightIn)
                    heightPicker.selectRow(feet - HeightPickerDelegate.Constants.MinHeightFt, inComponent: 0, animated: false)
                    heightPicker.selectRow(inches - HeightPickerDelegate.Constants.MinHeightIn, inComponent: 1, animated: false)
                    heightTextField.text = "\(feet)' \(inches)\""
                
                    let weightUS = min(max(WeightPickerDelegate.Constants.MinWeightLb, Int(round(DataFormatter.kilogramsToPounds(weightKg)))), WeightPickerDelegate.Constants.MaxWeightLb)
                    weightPicker.selectRow(weightUS - WeightPickerDelegate.Constants.MinWeightLb, inComponent: 0, animated: false)
                    weightTexField.text = "\(weightUS) " + Abbreviation.Pounds
                case .Metric:
                    let height = min(max(HeightPickerDelegate.Constants.MinHeightCm, Int(round(heightCm))), HeightPickerDelegate.Constants.MaxHeightCm)
                    heightPicker.selectRow(height - HeightPickerDelegate.Constants.MinHeightCm, inComponent: 0, animated: false)
                    heightTextField.text = "\(Int(round(heightCm))) " + Abbreviation.Centimetres
                    
                    let weight = min(max(WeightPickerDelegate.Constants.MinWeightKg, Int(round(weightKg))), WeightPickerDelegate.Constants.MaxWeightKg)
                    weightPicker.selectRow(weight - WeightPickerDelegate.Constants.MinWeightKg, inComponent: 0, animated: false)
                    weightTexField.text = "\(weight) " + Abbreviation.Kilograms
            }
            timePicker.locale = DataFormatter.locale
            datePicker.locale = DataFormatter.locale
            updateSleepTimeSettingTextFields()
            if Settings.sharedSettings.dayOfBirth != nil  {
                dateOfBirthTF.text = DataFormatter.stringFromDate(datePicker.date)
            }
        }
    }
    private var heightCm = Double(HeightPickerDelegate.Constants.MinHeightCm)
    private var weightKg = Double(WeightPickerDelegate.Constants.MinWeightLb)
    
    private var hasProfileBeenChanged: Bool {
        var dobEqual = false
        if let dob = Settings.sharedSettings.dayOfBirth, newDate = DataFormatter.dateFromString(dateOfBirthTF.text) {
            dobEqual = dob.compare(newDate) == .OrderedSame
        }
        var genderEqual = (Settings.sharedSettings.gender == (maleButton.selected ? .Male: .Female))
        var heightEqual = false
        if let height = Settings.sharedSettings.height {
            heightEqual = height.doubleValue == heightCm
        }
        var weightEqual = false
        if let weight = Settings.sharedSettings.weight {
            weightEqual = weight.doubleValue == weightKg
        }
        return !dobEqual || !genderEqual || !heightEqual || !weightEqual
    }
    
    private var hasSettingsBeenChanged: Bool {
        var numberOfLessonsEqual = Settings.sharedSettings.numberOfLessons.integerValue == numberOfLessonsSlider.currentValue
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
        tutorialViewController?.tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        (parentViewController as? SenseiTabController)?.delegate = nil
        NSNotificationCenter.defaultCenter().removeObserver(self, name: TutorialViewController.Notifications.TutorialDidHide, object: nil)
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//        saveSettings()
//    }
  
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleNoAnswerNotification:"), name: SpeechBubbleCollectionViewCell.Notifications.NoAnswer, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleYesAnswerNotification:"), name: SpeechBubbleCollectionViewCell.Notifications.YesAnswer, object: nil)
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
        Settings.sharedSettings.dayOfBirth = DataFormatter.dateFromString(dateOfBirthTF.text)
        Settings.sharedSettings.gender = maleButton.selected ? .Male: .Female
        Settings.sharedSettings.height = NSNumber(double: heightCm)
        Settings.sharedSettings.weight = NSNumber(double: weightKg)
    }
    
    private func updateSettings() {
        APIManager.sharedInstance.updateSettingsWithCompletion({ [weak self] (settings, error) -> Void in
            self?.fillFromSettings()
            println("After \(Settings.sharedSettings)")
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
        
        if let height = Settings.sharedSettings.height {
            heightCm = height.doubleValue
        } else {
            heightTextField.text = ""
        }
        
        if let weight = Settings.sharedSettings.weight {
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
    
    // MARK: - Tutorial
    
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
}

// MARK: - UITextFieldDelegate

extension SettingsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        firstResponder = textField
        if textField.inputView == timePicker {
            if let date = DataFormatter.timeFromString(textField.text) {
                timePicker.setDate(date, animated: false)
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        firstResponder = nil
    }
}

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

