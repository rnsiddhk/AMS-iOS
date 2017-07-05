//
//  AtmInfoCell.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 19..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class AtmInfoCell: UITableViewCell {

    @IBOutlet weak var lblTiltle: UILabel!
    
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
