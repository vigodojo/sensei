//
//  SettingsTableViewController.swift
//  Sensei
//
//  Created by Dmitry Kanivets on 29.05.15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet var settingsTableView: UITableView!
    
    @IBOutlet weak var numberOfLessonsSlider: VigoSlider!
    @IBOutlet weak var tutorialSwitch: UISwitch!

    @IBOutlet weak var weekDaysStartTF: UITextField! {
        didSet {
            weekDaysStartTF.inputView = datePicker
        }
    }
    @IBOutlet weak var weekDaysEndTF: UITextField! {
        didSet {
            weekDaysEndTF.inputView = datePicker
        }
    }
    @IBOutlet weak var weekEndsStartTF: UITextField! {
        didSet {
            weekEndsStartTF.inputView = datePicker
        }
    }
    @IBOutlet weak var weekEndsEndTF: UITextField! {
        didSet {
            weekEndsEndTF.inputView = datePicker
        }
    }
    @IBOutlet weak var dateOfBirthTF: UITextField!
    
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .Time
        return picker
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (parentViewController?.parentViewController as? SenseiNavigationControllerConteiner)?.tutorialHidden = !Settings.sharedSettings.tutorialOn.boolValue
        updateSettings()
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
    }

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
}
