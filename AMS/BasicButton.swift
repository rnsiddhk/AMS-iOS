//
//  BasicButton.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 10..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class BasicButton: UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius =  3.0
        self.clipsToBounds = true
    }
}
