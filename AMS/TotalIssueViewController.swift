//
//  TotalIssueViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 31..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class TotalIssueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var tbIssueList: UITableView!
    
    @IBOutlet weak var tfDatePicker: UITextField!
    
    let datePicker = UIDatePicker()
    
    let dateFormatter = DateFormatter()
    
    var refresh: UIRefreshControl!
    
    var branch_gb: String = ""  // 지사코드
    var team_gb: String = ""    // 채널코드
    var gijun_il: String = ""   // 기준일(전일)
    var org_cd: String = ""     // 기기번호
    var type: String = "0"      // 0:전일마감, 1:전월동일, 2:전월말일, 3:전년동일
    
    var jsonArr = Array<JSON>()
    
    var searchGB = "button"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "장애 유형별 건수"
        
        refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: "Waiting...")
        refresh.addTarget(self, action: #selector(pullToRefresh), for: UIControlEvents.valueChanged)
        tbIssueList.refreshControl = refresh
        
        // 현재날짜 정보 얻기
        let currentDate = NSDate()
        
        // 커스텀 datePicker 생성
        createDatePicker()
        
        // 현재 날짜 정보 텍스트에 보여주기
        tfDatePicker.text = dateFormatter.string(from: currentDate as Date)
        
        // 기준일 값 셋팅
        gijun_il = tfDatePicker.text!
        
        // datePicker 모드 설정
        datePicker.datePickerMode = .date

        searchData()

    }
    
    @IBAction func segSearch(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            searchGB = "button"
            type = "0"
            searchData()
        case 1:
            searchGB = "button"
            type = "1"
            searchData()
        case 2:
            searchGB = "button"
            type = "2"
            searchData()
        case 3:
            searchGB = "button"
            type = "3"
            searchData()
        default:
            break
        }
    }
    
    func pullToRefresh(){
        searchGB = "header"
        searchData()
    }
    
    func searchData(){
        
        if searchGB == "header" {
            refresh.beginRefreshing()
        } else {
            CSIndicator.shared.show(view)
        }
        

        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il")
        http.paramData.setValue(type, forKey: "type")
        
    
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(branch_gb, forKey: "branch_gb")
        http.paramData.setValue(team_gb, forKey: "team_gb")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        http.paramData.setValue(org_cd, forKey: "org_cd")
        http.paramData.setValue(type, forKey: "type")

        http.paramBox.setValue("statOb", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        print("매개변수 \(http.paramArray)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                let json = JSON(value)
                print(json)
                self.setSearchData(json)
                
            case .failure(let error):
                print("조회 실패 >>> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription)
                if self.searchGB == "header" {
                    self.refresh.endRefreshing()
                } else {
                    CSIndicator.shared.hide()
                }
            }
        }
    }

    func setSearchData(_ resJson: JSON) {
        
        jsonArr = resJson["statOb"]["list"].arrayValue
        
        tbIssueList.delegate = self
        tbIssueList.dataSource = self
        
        tbIssueList.reloadData()
        
        if searchGB == "header" {
            refresh.endRefreshing()
        } else {
            CSIndicator.shared.hide()
        }
    
    }
    
    // 커스텀 dataPicker 생성 함수
    func createDatePicker(){
        
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePressed))
        toolBar.setItems([doneButton], animated: true)
        
        tfDatePicker.inputAccessoryView = toolBar
        tfDatePicker.inputView = datePicker
        
    }
    // 완료 버튼 처리 함수
    func donePressed(){
        
        let date = dateFormatter.string(from: datePicker.date)
        
        tfDatePicker.text = date
        gijun_il = date
        self.view.endEditing(true)
        
    }
    
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
    
    /* tableView Delegate, Datasource */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jsonArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TotalIssueCell", for: indexPath) as! TotalIssueCell
        
        cell.lblTitle.text = FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_ATM_NM"].string)
        cell.lblContents.text = String(describing: jsonArr[indexPath.row]["FAILURE_COUNT"].int!)
        
        return cell
    }
    /* tableView Delegate, Datasource */
}
