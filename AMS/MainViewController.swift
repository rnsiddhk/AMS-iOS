//
//  MainViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 4. 27..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MainViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var lblUrgentCnt: BadgeLebel!
    
    @IBOutlet weak var lblIssueCnt: BadgeLebel!

    @IBOutlet weak var sbInput: UISearchBar!
    
    @IBOutlet weak var tbNotice: UITableView!
    
    var noticeList:[NoticeCell] = [NoticeCell]()
    
    var jsonArr: Array<JSON> = []
    
    var SEQ = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lblUrgentCnt.text = ""
        lblIssueCnt.text = ""
        
        sbInput.delegate = self
        self.navigationItem.title = "Mobile AMS"

    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.initData()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sbInput.resignFirstResponder()
    }
    
    func initData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ENT"), forKey: "user_ent")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")
        http.paramData.setValue("1", forKey: "startRow")
        http.paramData.setValue("5", forKey: "endRow")
        
        http.paramBox.setValue("main", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            print(response.result)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("메인화면 데이터 조회 성공 >> \(json)")
                
                if 0 < json["main"].count{
                    self.setData(json)
                } else {
                    CSIndicator.shared.hide()
                }

            case .failure(let error) :
                self.showAlert(error.localizedDescription)
                print("메인화면 데이터 조회 실패 >> \(error.localizedDescription)")
                CSIndicator.shared.hide()
            }
        }
    }
    func setData(_ resJson: JSON){
        
        if 0 < resJson["main"]["URGENT_COUNT"].int! {
            lblUrgentCnt.text = String(describing: resJson["main"]["URGENT_COUNT"].int!)
        } else {
            lblUrgentCnt.text = ""
        }

        if 0 < resJson["main"]["FAILURE_COUNT"].int! {
            lblIssueCnt.text = String(describing: resJson["main"]["FAILURE_COUNT"].int!)
        } else {
            lblIssueCnt.text = ""
        }
        
        jsonArr = resJson["main"]["noticeList"].arrayValue
 
        self.tbNotice.reloadData()

        CSIndicator.shared.hide()
    }
    
    @IBAction func btnNearAtmAction(_ sender: UIButton) {
        
        self.performSegue(withIdentifier: "segNearAtms", sender: nil)
    }
    
    @IBAction func btnSiteAction(_ sender: UIButton) {
        self.showAlert("서비스 준비중 입니다!")
    }

    func showAlert(_ msg: String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        

        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        toast.addAction(okAction)

        self.present(toast, animated: true, completion: nil)
    }
    
    /* TableView Delegate, DataSource */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jsonArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoticeCell", for: indexPath) as! NoticeCell

        if jsonArr[indexPath.row]["URGENT_YN"].string == "N" {
            cell.lblGubun.text = "일반"
            cell.lblGubun.textColor = UIColor.white
            cell.lblGubun.backgroundColor = UIColor(red: 0, green: 216/255, blue: 255/255 , alpha: 1)
        } else {
            cell.lblGubun.text = "긴급"
            cell.lblGubun.textColor = UIColor.white
            cell.lblGubun.backgroundColor = UIColor.red
        }
        
        if jsonArr[indexPath.row]["NOTICE_GB"].string == "0" {
            cell.lblCompayGB.text = "전사"
            cell.lblCompayGB.textColor = UIColor.white
            cell.lblCompayGB.backgroundColor = UIColor(red: 255/255, green: 130/255, blue: 36/255 , alpha: 1)
        } else {
            cell.lblCompayGB.text = "지사"
            cell.lblCompayGB.textColor = UIColor.white
            cell.lblCompayGB.backgroundColor = UIColor(red: 71/255, green: 200/255, blue: 62/255 , alpha: 1)
        }

        cell.lblTitle.text = jsonArr[indexPath.row]["TITLE"].string
        cell.lblDate.text = jsonArr[indexPath.row]["REG_DATE"].string
        cell.lblWriter.text = jsonArr[indexPath.row]["USER_NM"].string
        cell.lblCount.text = "조회:" + String(describing: jsonArr[indexPath.row]["VIEW_CNT"].int!)

        return cell
    }
    /* TableView Delegate, DataSource */

    /* searchBar Delegate */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        sbInput.endEditing(true)
        sbInput.resignFirstResponder()
        
        self.performSegue(withIdentifier: "Status", sender: nil)
    }
    /* searchBar Delegate */
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        SEQ = jsonArr[indexPath.row]["NOTICE_NO"].int!
 
        self.performSegue(withIdentifier: "segNoticeDt", sender: nil)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "Urgent" {
            
            let destination = segue.destination as! IssueViewController
            
            destination.downGB = "U"
            
        } else if segue.identifier == "Issue"{
            
            let destination = segue.destination as! IssueViewController
            
            destination.downGB = "I"
            
        } else if segue.identifier == "Status" {
            
            let destination = segue.destination as! StatusMgrViewController
            
            destination.keyword = sbInput.text!.trimmingCharacters(in: .whitespaces)
            
        } else if segue.identifier == "segNoticeDt" {
            let destination = segue.destination as! NoticeDetailViewController
            
            destination.SEQ = SEQ
            
        }else if segue.identifier == "segNearAtms" {
            let destination = segue.destination as! GoogleMapViewController
            
            destination.viewName = "NearAtms"
        }
    }
    
}
