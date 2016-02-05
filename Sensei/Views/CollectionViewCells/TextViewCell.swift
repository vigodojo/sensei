//
//  TextViewCell.swift
//  smth
//
//  Created by Sergey Sheba on 2/3/16.
//  Copyright © 2016 sergeysheba. All rights reserved.
//

import UIKit

protocol TextViewCellDelegate: class {
    func textViewDidScrollToBottom()
}

class TextViewCell: UICollectionViewCell, UITextFieldDelegate, UIScrollViewDelegate {
    
    weak var delegate: TextViewCellDelegate?
    
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        textView.flashScrollIndicators()
        textView.contentOffset = CGPointZero
    }
    
    override func prepareForReuse() {
        textView.flashScrollIndicators()
        textView.contentOffset = CGPointZero
    }
    

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == textView && scrollView.contentSize.height - scrollView.contentOffset.y <= scrollView.bounds.height {
            delegate?.textViewDidScrollToBottom()
        }
    }
}
