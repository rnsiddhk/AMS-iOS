//
//  NoticeCell.swift
//  AMS
//
//  Created by 정재호 on 2017. 4. 28..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class NoticeCell : UITableViewCell {
    
    @IBOutlet weak var lblGubun: UILabel!
    @IBOutlet weak var lblCompayGB: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblWriter: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
