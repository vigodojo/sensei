//
//  TextInputAccessoryView.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

enum KeyboardInputAccessoryViewType {
    case Text
    case Number
}

class KeyboardInputAccessoryView: UIView, AnswerableInputAccessoryViewProtocol {
    
    private struct Constants {
        static let NibName = "KeyboardInputAccessoryView"
        static let DefaultIndent: CGFloat = 8
    }

    @IBOutlet weak var textFieldLeadingConstraint: NSLayoutConstraint!
    
    var didSubmit: (() -> Void)?
    var didCancel: (() -> Void)?
    
    var type = KeyboardInputAccessoryViewType.Text {
        didSet {
            switch type {
                case .Text:
                    textFieldLeadingConstraint.constant = Constants.DefaultIndent
                    rightButton.setTitle("Cancel", forState: UIControlState.Normal)
                    textField.keyboardType = UIKeyboardType.Default
                case .Number:
                    textFieldLeadingConstraint.constant = Constants.DefaultIndent * 2 + CGRectGetWidth(leftButton.bounds)
                    rightButton.setTitle("Submit", forState: UIControlState.Normal)
                    textField.keyboardType = UIKeyboardType.NumberPad
            }
        }
    }
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    @IBAction func leftButtonAction() {
        if let didCancel = didCancel {
            didCancel()
        }
    }
    
    @IBAction func rightButtonAction() {
        switch type {
            case .Text:
                if let didCancel = didCancel {
                    didCancel()
                }
            case .Number:
                if let didSubmit = didSubmit {
                    didSubmit()
                }
        }
    }
    
    private func setup() {
        if let view = NSBundle.mainBundle().loadNibNamed(Constants.NibName, owner: self, options: nil).first as? UIView {
            addEdgePinnedSubview(view)
        }
    }
}
