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
    
    func answerableView(answerableView: AnswerableView, didSubmitAnswer answer: String)
    func answerableViewDidCancel(answerableView: AnswerableView)
}

class AnswerableView: UIView {
    
    private struct Constants {
        static let InputAccessotyViewHeight: CGFloat = 40
    }
    
    private var textInputAccessoryView = TextInputAccessoryView(frame: CGRectZero)
    private var pickerInputAccessoryView = PickerInputAccessoryView(frame: CGRectZero)
    private var answerType = AnswerType.Text
    
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
    
    override var inputAccessoryView: UIView? {
        switch answerType {
            case .Text: return textInputAccessoryView
            default : return pickerInputAccessoryView
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        if textInputAccessoryView.textField.isFirstResponder() {
            return false
        } else {
            return super.becomeFirstResponder()
        }
    }
    
    // MARK: - Public
    
    func askQuestion(question: Question) {
        answerType = question.answerType
        becomeFirstResponder()
    }
    
    // MARK: - Private
    
    private func setup() {
        let rect = CGRect(origin: CGPointZero, size: CGSize(width: CGRectGetWidth(bounds), height: Constants.InputAccessotyViewHeight))
        textInputAccessoryView.frame = rect
        textInputAccessoryView.textField.delegate = self
        textInputAccessoryView.didCancel = { [weak self] () -> Void in
            self?.textInputAccessoryView.textField.resignFirstResponder()
            self?.cancel()
        }
        pickerInputAccessoryView.frame = rect
        pickerInputAccessoryView.didCancel = { [weak self] () -> Void in
            self?.cancel()
        }
        pickerInputAccessoryView.didSubmit = { [weak self] () -> Void in
            self?.submitAnswer("Answer")
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if self?.inputView == nil {
                self?.textInputAccessoryView.textField.becomeFirstResponder()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) -> Void in
            if self?.inputView == nil {
                self?.textInputAccessoryView.textField.resignFirstResponder()
            } else {
                self?.resignFirstResponder()
            }
        }
    }
    
    private func cancel() {
        self.resignFirstResponder()
        if let delegate = delegate {
            delegate.answerableViewDidCancel(self)
        }
    }
    
    private func submitAnswer(answer: String) {
        if let delegate = delegate {
            delegate.answerableView(self, didSubmitAnswer: answer)
        }
    }
}

extension AnswerableView: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        resignFirstResponder()
        return true;
    }
}
