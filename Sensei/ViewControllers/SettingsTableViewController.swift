//
//  SettingsTableViewController.swift
//  Sensei
//
//  Created by Dmitry Kanivets on 29.05.15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    private struct Constants {
        static let MinHeightCm = 30
        static let MaxHeightCm = 272
        static let MinHeightFt = 1
        static let MaxHeightFt = 8
        static let MinHeightIn = 0
        static let MaxHeightIn = 11
        static let MinWeightKg = 11
        static let MaxWeightKg = 227
        static let MinWeightLb = 25
        static let MaxWeightLb = 500
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
    
    private lazy var dobFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    
    private lazy var timeFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
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
    
    private lazy var heightPicker: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private lazy var weightPicker: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private weak var firstResponder: UITextField?
    
    private var dataFormat = DataFormat.US {
        didSet {
            heightPicker.reloadAllComponents()
            weightPicker.reloadAllComponents()
            switch dataFormat {
                case .US:
                    let heightUS = DataFormat.centimetersToFeetAndInches(heightCm)
                    let feet = min(max(Constants.MinHeightFt, heightUS.0), Constants.MaxHeightFt)
                    let inches = min(max(Constants.MinHeightIn, Int(round(heightUS.1))), Constants.MaxHeightIn)
                    heightPicker.selectRow(feet - Constants.MinHeightFt, inComponent: 0, animated: false)
                    heightPicker.selectRow(inches - Constants.MinHeightIn, inComponent: 1, animated: false)
                    heightTextField.text = "\(feet)' \(inches)\""
                case .Metric:
                    let height = min(max(Constants.MinHeightCm, Int(round(heightCm))), Constants.MaxHeightCm)
                    heightPicker.selectRow(height - Constants.MinHeightCm, inComponent: 0, animated: false)
                    heightTextField.text = "\(Int(round(heightCm))) cm"
                    break
            }
        }
    }
    private var heightCm = Double(Constants.MinHeightCm)
    private var weightKg = Double(Constants.MinHeightFt)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (parentViewController?.parentViewController as? SenseiNavigationControllerConteiner)?.tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
        updateSettings()
        setup()
        fillFromSettings()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        saveSettings()
    }
  
    // MARK: - Private
    
    func setup() {
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
    
    private func saveSettings() {
        Settings.sharedSettings.numberOfLessons = NSNumber(integer: numberOfLessonsSlider.currentValue)
        Settings.sharedSettings.tutorialOn = NSNumber(bool: tutorialSwitch.on)
        Settings.sharedSettings.sleepTimeWeekdays.start = timeFormatter.dateFromString(weekDaysStartTF.text)!
        Settings.sharedSettings.sleepTimeWeekdays.end = timeFormatter.dateFromString(weekDaysEndTF.text)!
        Settings.sharedSettings.sleepTimeWeekends.start = timeFormatter.dateFromString(weekEndsStartTF.text)!
        Settings.sharedSettings.sleepTimeWeekends.end = timeFormatter.dateFromString(weekEndsEndTF.text)!
        Settings.sharedSettings.dayOfBirth = dobFormatter.dateFromString(dateOfBirthTF.text)
        Settings.sharedSettings.dataFormat = dataFormat
        Settings.sharedSettings.gender = maleButton.selected ? .Male: .Female
        Settings.sharedSettings.height = NSNumber(double: heightCm)
        Settings.sharedSettings.weight = NSNumber(double: weightKg)
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
        weekEndsStartTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekends.start)
        weekEndsEndTF.text = timeFormatter.stringFromDate(Settings.sharedSettings.sleepTimeWeekends.end)
        if let dayOfBirth = Settings.sharedSettings.dayOfBirth {
            dateOfBirthTF.text = dobFormatter.stringFromDate(dayOfBirth)
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
            weightTexField.text = "\(weight)"
        } else {
            weightTexField.text = ""
        }
        
        dataFormat = Settings.sharedSettings.dataFormat
        switch dataFormat {
            case .US : selectDataFormat(usDataFormatButton)
            case .Metric: selectDataFormat(metricDataFormatButton)
        }
        
        switch Settings.sharedSettings.gender {
            case .Male : selectGender(maleButton)
            case .Female: selectGender(femaleButton)
        }
    }
    
    private func heightWasChanged() {
        switch dataFormat {
            case .US:
                let feet = Constants.MinHeightFt + heightPicker.selectedRowInComponent(0)
                let inches = Constants.MinHeightIn + heightPicker.selectedRowInComponent(1)
                heightCm = DataFormat.feetAndInchToCm(feet, inches: Double(inches))
                heightTextField.text = "\(feet)' \(inches)\""
            case .Metric:
                heightCm = Double(Constants.MinHeightCm + heightPicker.selectedRowInComponent(0))
                heightTextField.text = "\(Int(round(heightCm))) cm"
        }
    }
    
    // MARK: - IBActions

    @IBAction func changedLessonsQuantity(sender: VigoSlider) {
        
        println("Lessons = \(sender.currentValue)")
    }
    
    @IBAction func toggleTutorial(sender: UISwitch) {
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
        dataFormat = usDataFormatButton.selected ? .US: .Metric
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
            if let date = timeFormatter.dateFromString(textField.text) {
                timePicker.setDate(date, animated: false)
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        firstResponder = nil
    }
}

// MARK: - UIPickerViewDataSource

extension SettingsTableViewController: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if pickerView == heightPicker {
            return dataFormat == .US ? 2: 1
        } else {
            return 1
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == heightPicker {
            switch (dataFormat, component) {
                case (.Metric, 0): return Constants.MaxHeightCm - Constants.MinHeightCm + 1
                case (.US, 0): return Constants.MaxHeightFt - Constants.MinHeightFt + 1
                case (.US, 1): return Constants.MaxHeightIn - Constants.MinHeightIn + 1
                default: return 0
            }
        } else {
            return 1
        }
    }
}

// MARK - UIPickerViewDelegate

extension SettingsTableViewController: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if pickerView == heightPicker {
            switch (dataFormat, component) {
                case (.Metric, 0): return "\(Constants.MinHeightCm + row) cm"
                case (.US, 0): return "\(Constants.MinHeightFt + row)'"
                case (.US, 1): return "\(Constants.MinHeightIn + row)\""
                default: return "="
            }
        } else {
            return "="
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == heightPicker {
            heightWasChanged()
        } else {
            
        }
    }
}
