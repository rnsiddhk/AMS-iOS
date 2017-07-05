//
//  GoodsInfoCell.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 22..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class GoodsInfoCell: UITableViewCell {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var lblInfo: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
