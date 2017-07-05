//
//  CustomLabel.swift
//  AMS
//
//  Created by 정재호 on 2017. 4. 28..
//  Copyright © 2017년 hirosi. All rights reserved.
//  Button badge로 사용
//

import UIKit


class BadgeLebel : UILabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius =  UIFont.smallSystemFontSize * CGFloat(0.5)
        self.textColor = UIColor.white
        self.backgroundColor = UIColor.red
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .height, multiplier: 1, constant: 0))
    }
}
