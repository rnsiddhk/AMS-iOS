//
//  CollectCell.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 29..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit

class CollectCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var lblContents: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
