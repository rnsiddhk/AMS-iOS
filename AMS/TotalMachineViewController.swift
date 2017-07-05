//
//  TotalMachineTableViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 30..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class TotalMachineViewController: UITableViewController {
    
    @IBOutlet var tbMachineList: UITableView!
    
    var refresh: UIRefreshControl!
    
    var isTop: Bool = false
    
    var customView: UIView!
    
    var btn_footer: UIButton!
    
    var branch_gb: String = ""
    
    var team_gb: String = ""
    
    var searchGB: String = "header"
    
    var PAGE_START: Int = 1           // 시작행
    var PAGE_END: Int = 25            // 마지막행
    
    var machineList = Array<BasicVO>()
    
    var basicVO = BasicVO()
    
    var jsonMachineList = Array<JSON>()
    
    var org_cd: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "기기 선택"
        
        // pull to refresh 하기 위헤 테이블뷰에 셋팅
        refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(pullToRefresh), for: UIControlEvents.valueChanged)
        tbMachineList.refreshControl = refresh
        
        // 커스텀 footer 셋팅하기
        customView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        
        customView.backgroundColor = UIColor(red: 60/255, green: 177/255, blue: 73/255, alpha: 1)
        
        btn_footer = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        
        btn_footer.setTitle("더보기", for: .normal)
        btn_footer.addTarget(self, action: #selector(footerSearch), for: .touchUpInside)
        
        btn_footer.center = customView.center
        customView.addSubview(btn_footer)
        
        searchData()
    }
    
    func pullToRefresh() {
        
        isTop = true
        PAGE_START = 1
        PAGE_END = 25
        searchGB = "header"
        searchData()
    }
    
    func footerSearch() {
        
        isTop = false
        PAGE_START = PAGE_END + 1
        PAGE_END = PAGE_END + 25
        searchGB = "footer"
        searchData()
        
    }
    
    func searchData(){
        
        if searchGB == "header" {
            refresh.beginRefreshing()
        } else {
            CSIndicator.shared.show(view)
        }

        
        let http = HttpRequest(option: "data")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(branch_gb, forKey: "branch_gb")
        http.paramData.setValue(team_gb, forKey: "team_gb")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ENT"), forKey: "user_ent")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        
        http.paramData.setValue(PAGE_START, forKey: "startRow")
        
        http.paramData.setValue(PAGE_END, forKey: "endRow")
        
        http.paramBox.setValue("selectAtm", forKey: "method")    // API 메소드명
        http.paramBox.setValue(http.paramData, forKey: "params")// parameter
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                self.setSearchData(json)
            case .failure(let error) :
                print("기기 선택 조회 실패 >> \(error.localizedDescription)")
                
                if self.searchGB == "header" {
                    self.refresh.endRefreshing()
                    
                } else {
                    CSIndicator.shared.hide()
                }
            }
        }
    }
    
    func setSearchData(_ resJson: JSON){
        
        jsonMachineList = resJson["selectAtm"]["list"].arrayValue
        
        if isTop {
            machineList.removeAll()
        }
        
        for i in 0..<jsonMachineList.count {
            
            basicVO = BasicVO()
            
            basicVO.data1 = jsonMachineList[i]["ATM_NM"].string!
            
            basicVO.data2 = jsonMachineList[i]["ORG_CD"].string!
            
            machineList.append(basicVO)
        }
        
        // 조회된 결과의 갯수가 25개인 경우 페이징처리 하기 위해 footer 셋팅
        if resJson["selectAtm"]["list"].count == 25 {
            tbMachineList.tableFooterView = customView
        } else {
            tbMachineList.tableFooterView = nil
        }
        
        if self.searchGB == "header" {
            
            self.refresh.endRefreshing()
            
        } else {
            CSIndicator.shared.hide()
        }
        
        self.tbMachineList.reloadData()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return machineList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MachineCell", for: indexPath)

        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = FunctionClass.shared.isNullOrBlankReturn(machineList[indexPath.row].data1)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        org_cd = machineList[indexPath.row].data2
        
        self.performSegue(withIdentifier: "segDevice", sender: nil)
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "segDevice" {
            let destination = segue.destination as! CollectMgrViewController
            destination.org_cd = org_cd
            destination.viewName = "device"
        }
        
    }
}
