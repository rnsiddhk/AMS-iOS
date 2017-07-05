//
//  TitleLabel.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 10..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class TitleLabel: UILabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius =  3.0
        self.textColor = UIColor.black
        self.backgroundColor = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1)
        self.clipsToBounds = true
    }
}
