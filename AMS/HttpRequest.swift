//
//  CommonValue.swift
//  AMS
//
//  Created by 정재호 on 2017. 4. 25..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import Foundation

class HttpRequest {

    // 실서버
    let SERVER_URL = URL(string: "http://210.105.193.181:10004/BGFMams/api/processor/work.do")
    let SERVER_IMAGE_URL = URL(string:"http://210.105.193.181:10004/BGFMams/api/common/upload.do")
    
    // 테스트 서버(tweb)
//    let SERVER_URL = URL(string: "http://210.105.193.144:10004/BGFMams/api/processor/work.do")
//    let SERVER_IMAGE_URL = URL(string: "http://210.105.193.144:10004/BGFMams/api/common/upload.do")
    
    var request: URLRequest
    var paramData : NSMutableDictionary
    var paramBox : NSMutableDictionary
    var paramArray : NSMutableArray
    
    init(option : String) {
        
        if option == "data"{
            self.request = URLRequest(url: self.SERVER_URL!)
        } else {
            self.request = URLRequest(url: self.SERVER_IMAGE_URL!)
        }

        self.request.httpMethod = "POST"
        self.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        self.paramData = NSMutableDictionary()
        self.paramBox = NSMutableDictionary()
        self.paramArray = NSMutableArray()
    }
    
}
