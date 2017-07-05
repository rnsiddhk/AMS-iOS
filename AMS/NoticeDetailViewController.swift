//
//  NoticeDetailViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 6. 1..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class NoticeDetailViewController: UIViewController {
    
    @IBOutlet weak var lblTitle: UILabel!
    
    @IBOutlet weak var lblGubun: UILabel!

    @IBOutlet weak var lblWriter: UILabel!
    
    @IBOutlet weak var lblTime: UILabel!
    
    @IBOutlet weak var txtContents: UITextView!
    
    var METHOD = "dscNotice"
    
    var search_gb = "2" // 0:이전, 1:다음, 2:현재
    
    var type = ""       // 조회타입
    
    var SEQ = 0         // 공지사항 순번
    
    var str_gb = ""     // 조회구분
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "공지사항 상세"
        
        searchData()
    }
    
    func searchData() {
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(SEQ, forKey: "notice_no")
        
        if search_gb != "2" {
            
            http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
            http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
            http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")
            http.paramData.setValue(type, forKey: "search_type")

        }

        http.paramBox.setValue(METHOD, forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            print(response.result)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("공지사항 상세 데이터 조회 성공 >> \(json)")
                
                if 0 < json[self.METHOD].count {
                    
                    if (self.search_gb == "2"){
                        self.setSearchData(json)
                        
                    } else {
                        self.setSearchGB(json)
                    }
                
                } else {
                    CSIndicator.shared.hide()
                    self.showAlert("조회된 내용이 없습니다!")
                }

            case .failure(let error) :
                self.showAlert(error.localizedDescription)
                print("공지사항 상세 데이터 조회 실패 >> \(error.localizedDescription)")
                CSIndicator.shared.hide()
            }
        }
    }
    // 현재 순번의 공지사항 정리 함수
    func setSearchData(_ resJson: JSON){
        
        // 타이틀
        lblTitle.text = "[" + FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["URGENT_YN"].string) + "]" +
        FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["TITLE"].string)
        
        // 조회구분
        let temp = FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["URGENT_YN"].string)
        
        if  temp == "0" {
            str_gb = "전체"
        } else if temp == "1" {
            str_gb = "임직원"
        } else {
            str_gb = "업체"
        }
        
        lblGubun.text = str_gb
        
        // 작성자
        lblWriter.text = FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["USER_NM"].string)
        
        // 작성시간
        lblTime.text = FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["REG_DATE"].string)
        // 내용
        txtContents.text = FunctionClass.shared.isNullOrBlankReturn(resJson[METHOD]["CONTENTS"].string)
        
        CSIndicator.shared.hide()
    
    }
    // 이전/다음 공지사항의 순번만 정리하는 함수
    // 정리 후 공지사항 내용 조회
    func setSearchGB(_ resJson: JSON) {
        
        SEQ = resJson[METHOD]["NOTICE_NO"].int!
        
        METHOD = "dscNotice"
        search_gb = "2"
        
        searchData()
    }
    
    func showAlert(_ msg: String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        toast.addAction(okAction)
        
        self.present(toast, animated: true, completion: nil)
    }
    
    @IBAction func previousAction(_ sender: UIButton) {
        
        search_gb = "0"
        METHOD = "preIdx"
        searchData()
    }
    
    @IBAction func nextAction(_ sender: UIButton) {
        search_gb = "1"
        METHOD = "nextIdx"
        searchData()
    }

}
