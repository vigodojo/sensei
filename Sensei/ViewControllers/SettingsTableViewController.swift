//
//  SettingsTableViewController.swift
//  Sensei
//
//  Created by Dmitry Kanivets on 29.05.15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    private lazy var dobFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    @IBOutlet var settingsTableView: UITableView!
    
    @IBOutlet weak var numberOfLessonsSlider: VigoSlider!
    @IBOutlet weak var tutorialSwitch: UISwitch!

    @IBOutlet weak var weekDaysStartTF: UITextField! {
        didSet {
            weekDaysStartTF.inputView = timePicker
            weekDaysStartTF.inputAccessoryView = pickerInputAccessoryView
        }
    }
    @IBOutlet weak var weekDaysEndTF: UITextField! {
        didSet {
            weekDaysEndTF.inputView = timePicker
            weekDaysEndTF.inputAccessoryView = pickerInputAccessoryView
        }
    }
    @IBOutlet weak var weekEndsStartTF: UITextField! {
        didSet {
            weekEndsStartTF.inputView = timePicker
            weekEndsStartTF.inputAccessoryView = pickerInputAccessoryView
        }
    }
    @IBOutlet weak var weekEndsEndTF: UITextField! {
        didSet {
            weekEndsEndTF.inputView = timePicker
            weekEndsEndTF.inputAccessoryView = pickerInputAccessoryView
        }
    }
    @IBOutlet weak var dateOfBirthTF: UITextField!
    @IBOutlet weak var weightTexField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var usDataFormatButton: UIButton!
    @IBOutlet weak var metricDataFormatButton: UIButton!
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    
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
    
    private weak var firstResponder: UITextField?
    
    private lazy var timeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (parentViewController?.parentViewController as? SenseiNavigationControllerConteiner)?.tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
        updateSettings()
        setup()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        saveSettings()
    }
  
    // MARK: Private
    
    func setup() {
        dateOfBirthTF.inputView = datePicker
        dateOfBirthTF.inputAccessoryView = pickerInputAccessoryView
        weightTexField.inputAccessoryView = pickerInputAccessoryView
        heightTextField.inputAccessoryView = pickerInputAccessoryView
    }
    
    private func saveSettings() {
        Settings.sharedSettings.sleepTimeWeekdays.start = timeFormatter.dateFromString(weekDaysStartTF.text)!
        Settings.sharedSettings.sleepTimeWeekdays.end = timeFormatter.dateFromString(weekDaysEndTF.text)!
        Settings.sharedSettings.sleepTimeWeekends.start = timeFormatter.dateFromString(weekEndsStartTF.text)!
        Settings.sharedSettings.sleepTimeWeekends.end = timeFormatter.dateFromString(weekEndsEndTF.text)!
        Settings.sharedSettings.dayOfBirth = dobFormatter.dateFromString(dateOfBirthTF.text)
        Settings.sharedSettings.height = NSNumber(integer:(heightTextField.text as NSString).integerValue)
        Settings.sharedSettings.weight = NSNumber(integer:(weightTexField.text as NSString).integerValue)
        APIManager.sharedInstance.saveSettings(Settings.sharedSettings, handler: nil)
        CoreDataManager.sharedInstance.saveContext()
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
        weekDaysStartTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekdays.start)
        weekDaysEndTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekdays.end)
        weekEndsStartTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekdays.start)
        weekEndsEndTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekdays.end)
        if let dayOfBirth = Settings.sharedSettings.dayOfBirth {
            dateOfBirthTF.text = dobFormatter.stringFromDate(dayOfBirth)
        } else {
            dateOfBirthTF.text = ""
        }
        
        if let height = Settings.sharedSettings.height {
            heightTextField.text = "\(height)"
        } else {
            heightTextField.text = ""
        }
        
        if let weight = Settings.sharedSettings.weight {
            weightTexField.text = "\(weight)"
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
    
    // MARK: IBActions

    @IBAction func changedLessonsQuantity(sender: VigoSlider) {
        Settings.sharedSettings.numberOfLessons = NSNumber(integer: sender.currentValue)
        println("Lessons = \(sender.currentValue)")
    }
    
    @IBAction func toggleTutorial(sender: UISwitch) {
        Settings.sharedSettings.tutorialOn = NSNumber(bool: sender.on)
        if let senseiNavigationController = parentViewController?.parentViewController as? SenseiNavigationController {
            if sender.on {
                senseiNavigationController.showTutorialAnimated(true)
            } else {
                senseiNavigationController.hideTutorialAnimated(true)
            }
        }
    }
    
    @IBAction func timePickerDidChangeValue(sender: UIDatePicker) {
        if let textField = firstResponder {
            textField.text = timeFormatter.stringFromDate(sender.date)
        }
    }
    
    @IBAction func datePickerDidChangeValue(sender: UIDatePicker) {
        dateOfBirthTF.text = dobFormatter.stringFromDate(sender.date)
    }
    
    @IBAction func selectDataFormat(sender: UIButton) {
        usDataFormatButton.selected = (sender == usDataFormatButton)
        metricDataFormatButton.selected = (sender == metricDataFormatButton)
        Settings.sharedSettings.dataFormat = usDataFormatButton.selected ? .US: .Metric
    }
    
    @IBAction func selectGender(sender: UIButton) {
        maleButton.selected = (sender == maleButton)
        femaleButton.selected = (sender == femaleButton)
        Settings.sharedSettings.gender = maleButton.selected ? .Male: .Female
    }
}

extension SettingsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(textField: UITextField) {
        firstResponder = textField
        if textField.inputView == timePicker {
            if let date = timeFormatter.dateFromString(textField.text) {
                timePicker.setDate(date, animated: false)
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        firstResponder = nil
    }
}
