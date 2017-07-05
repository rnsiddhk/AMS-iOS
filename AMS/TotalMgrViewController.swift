//
//  TotalMgrViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 29..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class TotalMgrViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet weak var tfJisa: UITextField!
    
    @IBOutlet weak var tfChannel: UITextField!
    
    @IBOutlet weak var tbMenu: UITableView!
    
    var jsonArr: Array<JSON> = []
    
    var json: JSON = []
    
    var jisaList = Array<BasicVO>()     // 지사 리스트
    var channelList = Array<BasicVO>()  // 채널 리스트
    
    var selectedRowForJs: Int = -1   // 지사구분 선택 row
    var selectedRowForCh: Int = -1   // 채널구분 선택 row
    
    var selected_jisa: String = ""    // 선택한 지사 값
    var selected_ch: String = ""      // 선택한 채널 값
    
    var basicVO: BasicVO = BasicVO()
    
    let imageList = ["icon_01.png", "icon_02.png", "icon_03.png", "icon_04.png"]
    
    let menuNM = ["일/월별 종합집계", "기기별 종합 집계", "장애 유형별 건수", "파출수납 관리"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.title = "집계관리"
        
        tbMenu.delegate = self
        tbMenu.dataSource = self
        tbMenu.reloadData()
        
        let footerView = UIView()
        
        footerView.backgroundColor = UIColor.clear
        
        tbMenu.tableFooterView = footerView
        
        jisaSearch()
        
    }
    
    /* 지사코드 조회 함수 */
    func jisaSearch(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")
        print("유저 그룹 >> \(UserDefaults.standard.string(forKey: "USER_GROUP")!)")
        print("지사 코드 >> \(UserDefaults.standard.string(forKey: "BRANCH_GB")!)")
        
        http.paramBox.setValue("jisa", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            //            print(response)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("지사 코드 데이터 조회 성공 >> \(json)")
                self.setJisaCode(json)
            case .failure(let error) :
                print("지사 코드 데이터 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "E")
                CSIndicator.shared.hide()
            }
        }
    }
    
    /* 지사코드 조회 셋팅 함수 */
    func setJisaCode(_ resJson: JSON){
        
        jsonArr = resJson["jisa"]["list"].arrayValue
        
        var cnt:Int = 0
        
        basicVO = BasicVO()
        basicVO.data1 = "NO"
        basicVO.data2 = "-선택-"
        jisaList.append(basicVO)
        
        for i in 0 ..< jsonArr.count {
            
            basicVO = BasicVO()
            json = jsonArr[i]
            
            if UserDefaults.standard.string(forKey: "BRANCH_GB") == "00" {
                
                if cnt < 1 {
                    basicVO.data1 = "ALL"
                    basicVO.data2 = "전체"
                    
                    jisaList.append(basicVO)
                    cnt += 1
                }
                
                basicVO = BasicVO()
                
                basicVO.data1 = json["BRANCH_GB"].string!
                basicVO.data2 = json["BRANCH_GB_NM"].string!
                
            }else{
                basicVO.data1 = json["BRANCH_GB"].string!
                basicVO.data2 = json["BRANCH_GB_NM"].string!
            }
            
            jisaList.append(basicVO)
        }
        
        CSIndicator.shared.hide()
        
        if 1 < self.jisaList.count {
            tfJisa.text = self.jisaList[1].data2
            self.selected_jisa = self.jisaList[1].data1
            selectedRowForJs = 1
            
            print("셋팅된 지사 코드 >> \(self.selected_jisa)")

            self.channelSearch()
        }
    }
    
    /* 채널 코드 조회 함수 */
    func channelSearch(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        
        if selected_jisa == "ALL" {
            http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")
        } else {
            
            http.paramData.setValue(selected_jisa, forKey: "branch_gb")
        }
        
        http.paramBox.setValue("channel", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            //            print(response)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("채널 코드 데이터 조회 성공 >> \(json)")
                self.setChannel(json)
            case .failure(let error) :
                print("채널 코드 데이터 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "E")
                CSIndicator.shared.hide()
            }
        }
    }
    
    /* 채널코드 조회 셋팅 함수 */
    func setChannel(_ resJson: JSON){
        
        jsonArr = resJson["channel"]["list"].arrayValue
        
        // 초기화
        if 0 < channelList.count {
            channelList.removeAll()
        }
        
        basicVO = BasicVO()
        basicVO.data1 = "NO"
        basicVO.data2 = "-선택-"
        channelList.append(basicVO)
        
        var cnt:Int = 0
        
        for i in 0 ..< jsonArr.count {
            
            basicVO = BasicVO()
            json = jsonArr[i]
            
            if UserDefaults.standard.string(forKey: "BRANCH_GB") == "00" || UserDefaults.standard.string(forKey: "USER_GRADE") == "5" {
                
                if cnt < 1 {
                    basicVO.data1 = "ALL"
                    basicVO.data2 = "전체"
                    
                    channelList.append(basicVO)
                    cnt += 1
                    
                }
                
                if json["TEAM_GB"].string != "0"{
                    
                    basicVO = BasicVO()
                    basicVO.data1 = json["TEAM_GB"].string!
                    basicVO.data2 = json["TEAM_GB_NM"].string!
                    
                    channelList.append(basicVO)
                }
            } else {
                
                basicVO.data1 = json["TEAM_GB"].string!
                basicVO.data2 = json["TEAM_GB_NM"].string!
                
                channelList.append(basicVO)
            }
        }
        
        if 0 < self.jisaList.count {
            
            createPicker(tfJisa, 300)
        }
        
        if 0 < self.channelList.count {
            
            createPicker(tfChannel, 400)
        }
        
        if 1 < self.channelList.count {
            tfChannel.text = self.channelList[1].data2
            self.selected_ch = self.channelList[1].data1
            selectedRowForCh = 1
        }
        
        CSIndicator.shared.hide()
        
    }
    
    /* 커스텀 PickerView 생성 함수 */
    func createPicker(_ textField : UITextField, _ tagId: Int){
        
        let pv = UIPickerView()
        
        // 커스텀 PickerView 생성
        pv.tag = tagId
        pv.frame = CGRect(x: 0, y: 0, width: 270, height: 150)
        pv.backgroundColor = UIColor.white
        pv.showsSelectionIndicator = true
        pv.delegate = self
        pv.dataSource = self
        
        // 커스텀 toolBar 생성
        let toolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        // toolBar에서 사용할 완료, 취소 공백 버튼 생성
        let doneButton = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(self.doneButton(sender:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(doneButton(sender:)))
        
        // toolBar에 생성한 버튼 셋팅
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: true)
        
        // 텍스트 필드의 프로퍼티 연결 PickerView, toolBar
        textField.inputView = pv
        textField.inputAccessoryView = toolbar
    }
    
    /* 커스텀 PickerView에서 선택한 값 처리 함수 */
    func doneButton(sender: UIBarButtonItem){
        
        if sender.title == "완료" {

            if -1 < self.selectedRowForJs {
                
                if self.selectedRowForJs != 0 {
                    tfJisa.text = self.jisaList[self.selectedRowForJs].data2
                    self.selected_jisa = self.jisaList[self.selectedRowForJs].data1
                    print("선택된 지사 코드 \(self.selected_jisa)")
                    
                    channelSearch()
                }
            }
            if -1 < self.selectedRowForCh {
                
                if self.selectedRowForCh != 0{
                    tfChannel.text = self.channelList[self.selectedRowForCh].data2
                    self.selected_ch = self.channelList[self.selectedRowForCh].data1
                }
            }
        }
        
        tfJisa.resignFirstResponder()
        tfChannel.resignFirstResponder()
    }
    
    // E: 에러 알림, N: 일반 알림
    func showAlert(_ msg: String, _ kind: String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        
        if kind == "E" {
            let okAction = UIAlertAction(title: "확인", style: .default) { (UIAlertAction) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    toast.dismiss(animated: true, completion: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
            toast.addAction(okAction)
            
        } else if kind == "N"{
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            toast.addAction(okAction)
        }
        
        self.present(toast, animated: true, completion: nil)
    }

    /* tableView Delegate, Datasource */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TotalMgrCell", for: indexPath) as! TotalMgrCell
        
        cell.imgMenu.image = UIImage(named: imageList[indexPath.row])
        cell.lblTitle.text = menuNM[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            self.performSegue(withIdentifier: "segCollectMgr", sender: nil)
        case 1:
            self.performSegue(withIdentifier: "segSelectAtm", sender: nil)
        case 2:
            self.performSegue(withIdentifier: "segTotalIssue", sender: nil)
        case 3:
            self.showAlert("서비스 준비중 입니다!", "N")
        default:
            break
        }
    }
    /* tableView Delegate, Datasource */
    
    /* pikcerView Delgate, Datasource */
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.tag == 300 {
            return jisaList.count
        } else {
            return channelList.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.tag == 300 {
            return jisaList[row].data2
        } else {
            return channelList[row].data2
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if pickerView.tag == 300 {
            selectedRowForJs = row
        } else {
            selectedRowForCh = row
        }
    }
    
    /* pikcerView Delgate, Datasource */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "segCollectMgr"{
        
            let destination = segue.destination as! CollectMgrViewController
            
            destination.branch_gb = jisaList[selectedRowForJs].data1
            destination.team_gb = channelList[selectedRowForCh].data1
            destination.viewName = "collect"
            
        } else if segue.identifier == "segSelectAtm" {
            let destination = segue.destination as! TotalMachineViewController
            
            destination.branch_gb = jisaList[selectedRowForJs].data1
            destination.team_gb = channelList[selectedRowForCh].data1
        
        } else if segue.identifier == "segTotalIssue" {
            
            let destination = segue.destination as! TotalIssueViewController
            
            destination.branch_gb = jisaList[selectedRowForJs].data1
            destination.team_gb = channelList[selectedRowForCh].data1
        
        }
    }

}
