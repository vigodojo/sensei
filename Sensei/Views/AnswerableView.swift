//
//  AnswerableView.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

protocol AnswerableInputAccessoryViewProtocol {
    
    var didSubmit: (() -> Void)? { get set}
    var didCancel: (() -> Void)? { get set}
}

protocol AnswerableViewDelegate: class {
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: Answer)
    func answerableViewDidCancel(answerableView: AnswerableView)
}

let DefaultInputAccessotyViewHeight: CGFloat = 40

class AnswerableView: UIView {
    
    private var questionType = QuestionType.Text
    private var pickerOptions = [String]()
    
    private lazy var pickerInputAccessoryView: PickerInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = PickerInputAccessoryView(frame: rect)
        inputAccessoryView.didCancel = { [weak self] () -> Void in
            self?.cancel()
        }
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            if let answer = self?.pickerAnswer() {
                self?.submitAnswer(answer)
            } else {
                self?.cancel()
            }
        }
        return inputAccessoryView
    }()
    
    private lazy var keyboardInputAccessoryView: KeyboardInputAccessoryView = { [unowned self] in
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(self.bounds), height: DefaultInputAccessotyViewHeight))
        let inputAccessoryView = KeyboardInputAccessoryView(frame: rect)
        inputAccessoryView.textField.delegate = self
        inputAccessoryView.didSubmit = { [weak self] () -> Void in
            if let answerText = self?.keyboardInputAccessoryView.textField.text where !answerText.isEmpty {
                self?.submitAnswer(Answer.Text(answerText))
            } else {
                self?.cancel()
            }
        }
        inputAccessoryView.didCancel = { [weak self] () -> Void in
            self?.keyboardInputAccessoryView.textField.resignFirstResponder()
            self?.cancel()
        }
        return inputAccessoryView
    }()
    
    private lazy var dateInputView: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = UIDatePickerMode.Date
        return datePicker
    }()
    
    private lazy var pickerInputView: UIPickerView = { [unowned self] in
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()
    
    private let heightPickerDelegate = HeightPickerDelegate()
    private let weightPickerDelegate = WeightPickerDelegate()
    
    weak var delegate: AnswerableViewDelegate?
    
    // MARK: - Lifecycle
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        println("\(classForCoder) ist Tod")
    }
    
    // MARK - UIResponder

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        if keyboardInputAccessoryView.textField.isFirstResponder() {
            return false
        } else {
            return super.becomeFirstResponder()
        }
    }
    
    override var inputAccessoryView: UIView? {
        switch questionType {
            case .Text:
                keyboardInputAccessoryView.type = KeyboardInputAccessoryViewType.Text
                return keyboardInputAccessoryView
            case .Number:
                keyboardInputAccessoryView.type = KeyboardInputAccessoryViewType.Number
                return keyboardInputAccessoryView
            default : return pickerInputAccessoryView
        }
    }
    
    override var inputView: UIView? {
        switch questionType {
            case .Date:
                dateInputView.locale = DataFormatter.locale
                return dateInputView
            case .Length:
                pickerInputView.dataSource = heightPickerDelegate
                pickerInputView.delegate = heightPickerDelegate
                reloadPickerInputView()
                return pickerInputView
            case .Mass:
                pickerInputView.dataSource = weightPickerDelegate
                pickerInputView.delegate = weightPickerDelegate
                reloadPickerInputView()
                return pickerInputView
            case .Choice:
                pickerInputView.dataSource = self
                pickerInputView.delegate = self
                reloadPickerInputView()
                return pickerInputView
            default:
                return nil
        }
    }
    
    // MARK: - Public
    
    func askQuestion(question: Question) {
        questionType = question.questionType
        pickerOptions = question.answers
        becomeFirstResponder()
    }
    
    // MARK: - Private
    
    private func setup() {
        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if self?.inputView == nil {
                self?.keyboardInputAccessoryView.textField.becomeFirstResponder()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if self?.inputView == nil {
                self?.keyboardInputAccessoryView.textField.resignFirstResponder()
            } else {
                self?.resignFirstResponder()
            }
        }
    }
    
    private func pickerAnswer() -> Answer? {
        switch questionType {
            case .Date:
                return Answer.Date(dateInputView.date)
            case .Choice:
                let selectedRow = pickerInputView.selectedRowInComponent(0)
                if selectedRow > -1 {
                    return  Answer.Text(pickerOptions[selectedRow])
                }
                return nil
            case .Length:
                return Answer.Height(heightPickerDelegate.currentValueForPickerView(pickerInputView))
            case .Mass:
                return Answer.Weight(weightPickerDelegate.currentValueForPickerView(pickerInputView))
            default:
                return nil
        }
    }
    
    private func cancel() {
        self.resignFirstResponder()
        delegate?.answerableViewDidCancel(self)
    }
    
    private func submitAnswer(answer: Answer) {
        resignFirstResponder()
        keyboardInputAccessoryView.textField.resignFirstResponder()
        delegate?.answerableView(self, didSubmitAnswer: answer)
        keyboardInputAccessoryView.textField.text = ""
    }
    
    private func reloadPickerInputView() {
        pickerInputView.reloadAllComponents()
        for component in 0..<pickerInputView.numberOfComponents {
            if pickerInputView.numberOfRowsInComponent(component) > 0 {
                pickerInputView.selectRow(0, inComponent: component, animated: false)
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension AnswerableView: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        submitAnswer(Answer.Text(textField.text))
        return true;
    }
}

// MARK: - UIPickerViewDataSource

extension AnswerableView: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
}

// MARK: - UIPickerViewDelegate

extension AnswerableView: UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return pickerOptions[row]
    }
}
