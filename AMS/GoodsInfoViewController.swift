//
//  GoodsInfoViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 22..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class GoodsInfoViewController: UITableViewController {
    
    @IBOutlet var tbGoodsList: UITableView!
    
    let strTitle: [String] = ["기기명", "기기번호", "현재잔액", "현송주기", "기기등급", "최근현송일", "전주출금액", "일평균", "현송계획"]
    var strInfo: [String] = []
    
    var org_cd: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "시재정보"
        
        print("GoodsInfoViewController 넘어온 값 >> \(org_cd)")
        initData()
    }
    
    func initData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")
        
        http.paramBox.setValue("goods", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print(json)
                
                if 0 < json["goods"].count{
                    self.setInitData(json)
                } else {
                    CSIndicator.shared.hide()
                    self.showAlert("조회된 내용이 없습니다!")
                }

            case .failure(let error) :
                print("시재 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription)
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setInitData(_ resJson: JSON){
        
        // 기기명
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["ATM_NM"].string))
        
        // 기기번호
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["ORG_CD"].string))
        
        // 현재잔액
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["REMAIN_AMT"].string).trimmingCharacters(in: .whitespaces) + " (단위:만원)")
        
        // 현송주기
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["SIJE_PERIOD"].string))
        
        // 기기등급
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["ATM_GRADE"].string))
        
        // 최근현송일
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["LAST_SIJE_DATE"].string))
        
        // 전주출금엑
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["PREV_AMT"].string).trimmingCharacters(in: .whitespaces) + " (단위:만원)")
        
        // 일평균
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["DAY_AVR_AMT"].string).trimmingCharacters(in: .whitespaces) + " (단위:만원)")
        
        // 현송계획
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(resJson["goods"]["SIJE_PLAN"].string))
        
        tbGoodsList.tag = 100
        
        tbGoodsList.delegate = self
        tbGoodsList.dataSource = self
        tbGoodsList.reloadData()
        
        CSIndicator.shared.hide()
    }

    
    // U: 데이터 입력처리 후 알림, N: 일반 알림, 데이터 통신 장애
    func showAlert(_ msg: String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        

        let okAction = UIAlertAction(title: "확인", style: .default) { (UIAlertAction) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    toast.dismiss(animated: true, completion: nil)
                    self.navigationController?.popViewController(animated: true)
            }
        }
        toast.addAction(okAction)

        self.present(toast, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if tableView.tag == 100 {
            return strTitle.count
        } else {
            return 0
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GoodsInfoCell", for: indexPath) as! GoodsInfoCell
        
        if tableView.tag == 100 {
            cell.lblTitle.text = strTitle[indexPath.row]
            cell.lblInfo.text = strInfo[indexPath.row]
            cell.lblInfo.numberOfLines = 2
            cell.lblInfo.adjustsFontSizeToFitWidth = true
        }

        return cell
    }
}
