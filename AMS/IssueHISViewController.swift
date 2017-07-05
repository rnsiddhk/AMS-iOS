//
//  IssueHISViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 19..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class IssueHISViewController: UITableViewController {

    @IBOutlet var tbIssueList: UITableView!
    
    var org_cd: String = ""
    var jsonArr: [JSON] = []
    var refresh: UIRefreshControl!
    var isRefresh: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: "Waiting...")
        refresh.addTarget(self, action: #selector(pullToRefesh), for: UIControlEvents.valueChanged)
        tbIssueList.refreshControl = refresh
        
        tbIssueList.delegate = self
        tbIssueList.dataSource = self
        
        self.navigationItem.title = "장애이력"
        
        initData()

    }

    func pullToRefesh(){
        
        isRefresh = true
        initData()
    }
    
    func initData(){
        
        if !isRefresh {
             CSIndicator.shared.show(view)
        }
        
        let http = HttpRequest(option: "data")
        
        
        http.paramData.setValue(org_cd, forKey: "org_cd")           // 기기번호

        http.paramBox.setValue("obHistory", forKey: "method")    // API 메소드명
        http.paramBox.setValue(http.paramData, forKey: "params")// parameter
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print("장애 이력 조회 성공")
                self.setData(json)
            case .failure(let error) :
                print("장애 이력 조회 실패 >> \(error.localizedDescription)")
                if self.isRefresh {
                    self.refresh.endRefreshing()
                } else {
                    CSIndicator.shared.hide()
                }
                
            }
        }
    
    }
    
    func setData(_ resJson: JSON){
        
        jsonArr = resJson["obHistory"]["list"].arrayValue

        tbIssueList.reloadData()
        
        if isRefresh {
            self.refresh.endRefreshing()
        } else {
            CSIndicator.shared.hide()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return jsonArr.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "IssueCell", for: indexPath)

        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_TIME"].string) + " " +
        FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["DOWN_ATM_NM"].string)
        

        return cell
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
