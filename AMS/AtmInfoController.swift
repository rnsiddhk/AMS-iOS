//
//  AtmInfoController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 16..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class AtmInfoController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tbInfoList: UITableView!
    
    @IBOutlet weak var tbIssueList: UITableView!
    
    @IBOutlet weak var btnSave: BasicButton!
    
    @IBOutlet weak var txtMemo: UITextView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let strTitle: [String] = ["지사/채널", "기기번호", "기기명", "기기종류", "기기위치",
                              "회선업체", "간판업체", "부스업체", "주간장애", "야간장애",
                              "장애메세지", "설치점", "관리번호", "기기메모"]
    var strInfo: [String] = []
    
    var org_cd: String = ""
    
    var atm_memo: String = ""
    
    var jsonArr: [JSON] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("viewDidLoad 여기오냐?")
        // Do any additional setup after loading the view.
        self.navigationItem.title = "기기정보"
        
        btnSave.isEnabled = false
        txtMemo.isEditable = false
        
        scrollView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        
        scrollView.addGestureRecognizer(tapGesture)

    }
    
    // 조치내역 입력후 키보드 내리는 함수
    func btnTapped(sender: UITapGestureRecognizer){
        
        if sender.state == .ended{
            txtMemo.resignFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initData()
    }
    
    func initData(){
        print("initData 여기오냐?")
        print("기기값 >> \(org_cd)")
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")
        http.paramBox.setValue("atms", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                //self.setData(json)
                print(json)

                self.setData(json)
     
            case .failure(let error) :
                print("기기정보 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setData(_ jsonRes: JSON){
        
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["BRANCH_GB_NM"].string))
        
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ORG_CD"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ATM_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ATM_KD_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ADDR_RMK"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["LINE_ENT_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["SIGN_ENT_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["BOOTH_MAKER_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["DAY_ADMIN_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["NIGHT_ADMIN_NM"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["DOWN_CD1_NM"].string) + "("
            + FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["DOWN_CD1"].string) + ")")
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["OPTEL_NO"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["RCD_NO2"].string))
        strInfo.append(FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ATM_MEMO"].string))
        
        txtMemo.text = FunctionClass.shared.isNullOrBlankReturn(jsonRes["atms"]["info"]["ATM_MEMO"].string)
        
        tbInfoList.tag = 100
        
        tbInfoList.delegate = self
        tbInfoList.dataSource = self
        tbInfoList.reloadData()
        
        jsonArr = jsonRes["atms"]["list"].arrayValue

        tbIssueList.tag = 200
        tbIssueList.delegate = self
        tbIssueList.dataSource = self
        tbIssueList.reloadData()
        
        CSIndicator.shared.hide()
    }
    
    // 메모 입력 함수
    func inputData(){
    
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")
        http.paramData.setValue(atm_memo, forKey: "atm_memo")
        http.paramBox.setValue("modifyMemo", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print(json)
                self.setInputData(json)

            case .failure(let error) :
                print("메모 내용입력 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setInputData(_ resJson: JSON){
        
        CSIndicator.shared.hide()
        
        var msg: String = ""
        
        // 성공
        if resJson["modifyMemo"]["code"].int! == 0 {
            msg = "메모 내용이 입력 되었습니다."
        } else {
            msg = "메모 내용이 입력 되지않았습니다."
        }
        
        showAlert(msg, "U")
    }
    
    @IBAction func btnMemoAction(_ sender: BasicButton) {
        btnSave.isEnabled = true
        txtMemo.isEditable = true
    }
    

    @IBAction func btnSaveAction(_ sender: BasicButton) {
        
        atm_memo = txtMemo.text.trimmingCharacters(in: .whitespaces)
        txtMemo.resignFirstResponder()
        
        if atm_memo != "" {
            inputData()
        } else {
            self.showAlert("메모를 입력하여주세요!", "N")
        }
    }

    @IBAction func btnOtpAction(_ sender: BasicButton) {
        
        self.showAlert("서비스 준비중 입니다.", "N")
    }
    
    // U: 데이터 입력처리 후 알림, N: 일반 알림, 데이터 통신 장애
    func showAlert(_ msg: String, _ kind: String){
    
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        
        if kind == "U" {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView.tag == 100 {
            return strTitle.count
        } else {
            return jsonArr.count
        }

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
        
        if tableView.tag == 100 {
            let cell =  tableView.dequeueReusableCell(withIdentifier: "AtmInfoCelll", for: indexPath) as! AtmInfoCell
            
            cell.lblTiltle.text = strTitle[indexPath.row]
            
            cell.lblInfo.numberOfLines = 2
            cell.lblInfo.adjustsFontSizeToFitWidth = true
            cell.lblInfo.text = strInfo[indexPath.row]
            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "issueCell", for: indexPath)
            
            cell.textLabel?.numberOfLines = 2
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.textLabel?.text = FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_TIME"].string) + " " + FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_ATM_NM"].string) + " " + FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_REG_NM"].string)
            return cell
        
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
