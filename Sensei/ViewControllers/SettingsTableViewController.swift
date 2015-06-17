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
    
    @IBOutlet weak var dailyLessonsTF: UITextField!
    @IBOutlet weak var weekDaysStartTF: UITextField!
    @IBOutlet weak var weekDaysEndTF: UITextField!
    @IBOutlet weak var weekEndsStartTF: UITextField!
    @IBOutlet weak var weekEndsEndTF: UITextField!
    @IBOutlet weak var dateOfBirthTF: UITextField!
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .Time
        return picker
    }()
    
    
    func handleTimePicker (sender: UIDatePicker){
        var timeFormatter = NSDateFormatter()
        timeFormatter.dateStyle = .NoStyle
        timeFormatter.timeStyle = .ShortStyle
        weekDaysStartTF.text = timeFormatter.stringFromDate(sender.date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weekDaysStartTF.inputView = datePicker
    }

    @IBAction func changedLessonsQuantity(sender: VigoSlider) {
        println("Lessons = \(sender.currentValue)")
    }
}
