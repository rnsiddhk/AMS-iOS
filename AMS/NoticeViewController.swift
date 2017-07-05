//
//  NoticeViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 31..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class NoticeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tbNoticeList: UITableView!
    
    var jsonArr = Array<JSON>()
    
    var type: String = "1"
    var PAGE_START: Int = 1
    var PAGE_END: Int = 25
    
    var isTop: Bool = false
    
    var refresh: UIRefreshControl!
    
    var customView: UIView! // footer 영역 뷰
    
    var footerView: UIView! // footer 영역 뷰
    
    var btn_footer: UIButton! // footer 버튼
    
    var searchGB: String = "button"
    
    var SEQ  = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresh = UIRefreshControl()
        
        refresh.attributedTitle = NSAttributedString(string: "Waiting...")
        refresh.addTarget(self, action: #selector(pullToRefresh), for: UIControlEvents.valueChanged)
        
        tbNoticeList.refreshControl = refresh
       
        // 커스텀 footer 셋팅하기
        customView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        customView.backgroundColor = UIColor(red: 60/255, green: 177/255, blue: 73/255, alpha: 1)
        btn_footer = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        btn_footer.setTitle("더보기", for: .normal)
        btn_footer.addTarget(self, action: #selector(footerSearch), for: .touchUpInside)
        btn_footer.center = customView.center
        customView.addSubview(btn_footer)
        
        footerView = UIView()
        
        footerView.backgroundColor = UIColor.clear
        
        tbNoticeList.delegate = self
        tbNoticeList.dataSource = self
        
        searchData()
    }

    @IBAction func segSearch(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
            
        case 0:
            type = "1"
            PAGE_START = 1
            PAGE_END = 25
            searchGB = "button"
            searchData()
        case 1:
            type = "2"
            PAGE_START = 1
            PAGE_END = 25
            searchGB = "button"
            searchData()
        case 2:
            type = "3"
            PAGE_START = 1
            PAGE_END = 25
            searchGB = "button"
            searchData()

        default:
            break
        }
    }
    
    func pullToRefresh(){
        
        isTop = true
        PAGE_START = 1
        PAGE_END = 25
        searchGB = "header"
        searchData()
    
    }
    
    func footerSearch(){
        
        isTop = false
        
        print("footerSearch 호출")
        
        PAGE_START = PAGE_END + 1
        PAGE_END = PAGE_END + 25
        searchGB = "button"
        searchData()
        
    }
    
    func searchData(){
        
        if self.searchGB == "button" {
            CSIndicator.shared.show(view)
        } else {
            self.refresh.beginRefreshing()
        }
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        http.paramData.setValue(type, forKey: "search_type")
        http.paramData.setValue(PAGE_START, forKey: "startRow")
        http.paramData.setValue(PAGE_END, forKey: "endRow")
        
        http.paramBox.setValue("notice", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            print(response.result)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("공지사항 리스트 데이터 조회 성공 >> \(json)")
                self.setSearchData(json)
            case .failure(let error) :
                self.showAlert(error.localizedDescription)
                print("공지사항 리스트 데이터 조회 실패 >> \(error.localizedDescription)")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setSearchData(_ resJson: JSON){
    
        jsonArr = resJson["notice"]["list"].arrayValue
        
        if resJson["notice"]["list"].count == 25 {
            tbNoticeList.tableFooterView = customView
        } else {
            tbNoticeList.tableFooterView = footerView
        }
        
        self.tbNoticeList.reloadData()
        
        if self.searchGB == "button" {
            CSIndicator.shared.hide()
        } else {
            self.refresh.endRefreshing()
        }
    }
    
    func showAlert(_ msg: String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        toast.addAction(okAction)
        
        self.present(toast, animated: true, completion: nil)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SEQ = jsonArr[indexPath.row]["NOTICE_NO"].int!
        self.performSegue(withIdentifier: "segNoticeDt", sender: nil)
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "segNoticeDt" {
            let destination = segue.destination as! NoticeDetailViewController
            
            destination.SEQ = SEQ
        }
    }


}
