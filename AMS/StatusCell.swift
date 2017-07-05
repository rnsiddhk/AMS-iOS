//
//  StatusCell.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 22..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class StatusCell: UITableViewCell {

    @IBOutlet weak var lblDeviceNm: UILabel!
    
    @IBOutlet weak var imgGrade: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
