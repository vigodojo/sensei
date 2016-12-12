//
//  LoaderView.swift
//  Sensei
//
//  Created by Sergey Sheba on 11/23/16.
//  Copyright © 2016 ThinkMobiles. All rights reserved.
//

import UIKit

class LoaderView: UIView {

    var activityIndicator: UIActivityIndicatorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.tintColor = UIColor.whiteColor()
        activityIndicator.startAnimating()
        self.addSubview(activityIndicator)
        let screenSize = UIScreen.mainScreen().bounds.size
        activityIndicator.center = CGPoint(x: screenSize.width/2, y: screenSize.height/2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        guard let activityIndicator = activityIndicator else { return }
        let screenSize = UIScreen.mainScreen().bounds.size
        activityIndicator.center = CGPoint(x: screenSize.width/2, y: screenSize.height/2)
    }
}
