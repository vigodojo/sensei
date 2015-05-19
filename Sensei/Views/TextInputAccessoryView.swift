//
//  TextInputAccessoryView.swift
//  Sensei
//
//  Created by Sauron Black on 5/19/15.
//  Copyright (c) 2015 ThinkMobiles. All rights reserved.
//

import UIKit

class TextInputAccessoryView: UIView, AnswerableInputAccessoryViewProtocol {
    
    private struct Constants {
        static let NibName = "TextInputAccessoryView"
    }

    var didSubmit: (() -> Void)?
    var didCancel: (() -> Void)?
    
    @IBOutlet weak var textField: UITextField!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
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

extension UIView {
    
    func addEdgePinnedSubview(view: UIView) {
        view.frame = bounds
        addSubview(view)
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        let bindings = ["view": view]
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: bindings))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0.0-[view]-0.0-|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: bindings))
    }
}
