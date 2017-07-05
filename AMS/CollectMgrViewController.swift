//
//  CollectMgrViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 29..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class CollectMgrViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var segMenu: UISegmentedControl!
    
    @IBOutlet weak var tfDatePicker: UITextField!
    
    @IBOutlet weak var tbCollectList: UITableView!
    
    
    let datePicker = UIDatePicker()
    
    let dateFormatter = DateFormatter()
    
    var branch_gb: String = ""  // 지사코드
    var team_gb: String = ""    // 채널코드
    var gijun_il: String = ""   // 기준일(전일)
    var org_cd: String = ""     // 기기번호
    var type: String = "0"      // 0:전일마감, 1:전월동일, 2:전월말일, 3:전년동일
    
    // 일/월별 종합 집계 리스트 타이틀
    var titleCollect = [["일 평균 건수", "일 총 수수료 금액"], ["평균 건수", "총 수수료 금액"]]
    // 기기별 종합 집계 리스트 타이틀
    var titleDevice = [["일 총 수수료 금액"], ["평균 건수", "총 수수료 금액"], ["월 평균 재고 일수", "연 평균 재고 일수",
                              "월 평균 과다장입금액", "연 평균 과다장입금액", "월 평균 현금부족 건수"]]
    var sectionCollect: [String] = ["해당 일 누계", "해당 월 누계"]      // 일/월별 종합 집계 섹션 타이틀
    var sectionDevice: [String] = ["해당 일 누계", "해당 월 누계", "자금 최적화"] // 기기별 종합 집계 섹션 타이틀
    var subDevice = ["일", "일", "원", "원", "건"]
    var dData: [Double] = []    // 일 누계 정보
    var mData: [Double] = []    // 월 누계 정보
    var oData: [Double] = []    // 최적화 누계 정보
    var sectionData: [Int:[Double]] = [:]   // 컨텐츠 부분
    
    var viewName = ""
    
    var footerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("전달된 값 >> \(viewName) \(org_cd)")
        
        if viewName == "collect" {
            self.navigationItem.title = "일/월별 종합 집계"
        } else {
            self.navigationItem.title = "기기별 종합 집계"
        }

        
        // 현재날짜 정보 얻기
        let currentDate = NSDate()
        
        // interval 설정 (하루 전)
        let interval: TimeInterval = 60 * 60 * -24
        
        // 하루 전 날짜 정보 얻기
        let yesterday = NSDate(timeInterval: interval, since: currentDate as Date)
        
        // 커스텀 datePicker 생성
        createDatePicker()
        
        // 하루 전 날짜 정보 텍스트에 보여주기
        tfDatePicker.text = dateFormatter.string(from: yesterday as Date)
        
        // 기준일 값 셋팅
        gijun_il = tfDatePicker.text!
        
        // datePicker 모드 설정
        datePicker.datePickerMode = .date
        
        // datePicker 하루 전 정보 셋팅
        datePicker.date.addTimeInterval(interval)
        
        footerView = UIView()
        
        footerView.backgroundColor = UIColor.clear
        
        tbCollectList.tableFooterView = footerView

        searchData()
    }
    
    
    @IBAction func segSearch(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            type = "0"
            searchData()
        case 1:
            type = "1"
            searchData()
        case 2:
            type = "2"
            searchData()
        case 3:
            type = "3"
            searchData()
        default:
            break
        }
    }
    
    func searchData(){
        
        CSIndicator.shared.show(view)
    
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il")
        http.paramData.setValue(type, forKey: "type")
    
        if viewName == "collect" {
            http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
            http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
            http.paramData.setValue(branch_gb, forKey: "branch_gb")
            http.paramData.setValue(team_gb, forKey: "team_gb")
            http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
            http.paramBox.setValue("stat", forKey: "method")
            
        } else {
            http.paramData.setValue(org_cd, forKey: "org_cd")
            http.paramBox.setValue("statAtm", forKey: "method")
        }
        

        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        print("매개변수 \(http.paramArray)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                let json = JSON(value)
                print(json)
                
                if self.viewName == "collect" {
                    
                    if 0 < json["stat"].count {
                        self.setSearchData(json)
                    } else {
                        CSIndicator.shared.hide()
                        self.showAlert("조회된 내용이 없습니다!")
                    }
                    
                } else {
                    
                    if 0 < json["statAtm"].count {
                        self.setSearchData(json)
                    } else {
                        CSIndicator.shared.hide()
                        self.showAlert("조회된 내용이 없습니다!")
                    }
                }

            case .failure(let error):
                self.showAlert(error.localizedDescription)
                print("조회 실패 >>> \(error.localizedDescription)")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setSearchData(_ resJson: JSON) {
        
        
        if 0 < dData.count {
            dData.removeAll()
        }
        
        if 0 < mData.count {
            mData.removeAll()
        }
        
        if 0 < oData.count {
            oData.removeAll()
        }
        
        if 0 < sectionData.count {
            sectionData.removeAll()
        }
        
        if self.viewName == "collect" {
            
            dData.append(resJson["stat"]["AVR_TOT_CNT"].double!)
            dData.append(resJson["stat"]["DAY_FEE_TOT_AMT"].double!)
        
            mData.append(resJson["stat"]["MON_AVR_TOT_CNT"].double!)
            mData.append(resJson["stat"]["MON_FEE_TOT_AMT"].double!)
            
            sectionData = [0 : dData, 1 : mData]
            
        } else {
            
            dData.append(resJson["statAtm"]["DAY_FEE_TOT_AMT"].double!)
            
            mData.append(resJson["statAtm"]["AVR_TOT_CNT"].double!)
            mData.append(resJson["statAtm"]["MON_FEE_TOT_AMT"].double!)
            
            oData.append(resJson["statAtm"]["M_S_DAY_CNT"].double!)
            oData.append(resJson["statAtm"]["Y_S_DAY_CNT"].double!)
            oData.append(resJson["statAtm"]["M_OVER_SIJE_AMT"].double!)
            oData.append(resJson["statAtm"]["Y_OVER_SIJE_AMT"].double!)
            oData.append(resJson["statAtm"]["L_CASH_CNT"].double!)
            
            sectionData = [0 : dData, 1 : mData, 2: oData]
        
        }

        tbCollectList.tag = 100
        tbCollectList.delegate = self
        tbCollectList.dataSource = self
        
        tbCollectList.reloadData()
        
        CSIndicator.shared.hide()
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
    
    // 알림 함수
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
    
    /* tableView delegate, tableView datasource */
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView.tag == 100 {
            
            if viewName == "collect"{
                return sectionCollect.count
            } else {
                return sectionDevice.count
            }

        } else {
            return 0
        }

    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView.tag == 100 {
            
            if viewName == "collect"{
                return self.sectionCollect[section]
            } else {
                return self.sectionDevice[section]
            }
            
        } else {
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView.tag == 100 {
            return (sectionData[section]?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectCell", for: indexPath) as! CollectCell
        
        if viewName == "collect" {
            cell.lblTitle.text = titleCollect[indexPath.section][indexPath.row]
        } else {
            cell.lblTitle.text = titleDevice[indexPath.section][indexPath.row]
        }

        if indexPath.section < 2 {
            cell.lblContents.text = FunctionClass.shared.decimalStyle(sectionData[indexPath.section]![indexPath.row])
        } else {
            cell.lblContents.text = FunctionClass.shared.decimalStyle(sectionData[indexPath.section]![indexPath.row]) + subDevice[indexPath.row]
        }
        
        return cell
        
    }
    /* tableView delegate, tableView datasource */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
