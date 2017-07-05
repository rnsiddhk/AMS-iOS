//
//  FunctionClass.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 17..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import Foundation
import UIKit

open class FunctionClass {
    
    open class var shared: FunctionClass{
    
        struct Static{
            
            static let instance: FunctionClass = FunctionClass()
        }
        
        return Static.instance
    }
    
    open func isNullOrNil(_ value: AnyObject?) -> Bool{
        
        if value == nil {
            return true
        } else {
            return false
        }
    }
    
    // true : null 값
    // false: 값이 있는 경우
    open func isNullOrBlank(_ str: String?)->Bool{
        
        guard str != nil else {
            return true
        }
        
        return false
    }
    // 값이 없을 경우, nil 인 경우 "" 값 리턴
    // 값이 있을 경우 원래 값 리턴
    open func isNullOrBlankReturn(_ str: String?)->String{
        
        guard str != nil else{
        
            return ""
        }
   
        return str!
    }
    
    // Base64 인코딩 함수
    open func base64Encoding(_ str: String) -> String? {
        
        if let data = str.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    // 썸네일 이미지 만드는 함수
    open func thumbnailImage(_ image: UIImage) -> UIImage {
        
        let size = image.size
        
        let targetSize = CGSize(width: 200.0, height: 200.0)
        
        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // 리사이징한 이미지의 사각형을 이미지 컨택스트에서 사용하기
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        
        // 이미지 그리기
        image.draw(in: rect)
        
        // 이미지 컨택스트에서 현재 그린 이미지 가져오기
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 이미지 컨택스트 종료
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    open func decimalStyle(_ value: Double) -> String {
    
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        
        if let formattedAmount = formatter.string(from: value as NSNumber) {
            return formattedAmount
        }
        
        return ""
    }
    
}

