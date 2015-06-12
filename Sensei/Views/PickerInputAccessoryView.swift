//
//  PickerInputAccessoryView.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class PickerInputAccessoryView: UIView, AnswerableInputAccessoryViewProtocol {
    
    private struct Constants {
        static let NibName = "PickerInputAccessoryView"
    }
    
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    var didSubmit: (() -> Void)?
    var didCancel: (() -> Void)?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @IBAction func submit() {
        if let didSubmit = didSubmit {
            didSubmit()
        }
    }
    
    @IBAction func cancel() {
        if let didCancel = didCancel {
            didCancel()
        }
    }
    
    private func setup() {
        if let view = NSBundle.mainBundle().loadNibNamed(Constants.NibName, owner: self, options: nil).first as? UIView {
            addEdgePinnedSubview(view)
        }
    }
}
