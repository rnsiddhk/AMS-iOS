//
//  SearchLocationViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 6. 8..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

protocol SearchViewControllerDelegate {
    func searchViewControllerResponse(x: Double, y: Double, org_cd: String, device_nm: String)
}

class SearchLocationViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet var tbLocationList: UITableView!
    
    var jsonArr = Array<JSON>()
    
    var keyword = ""                // 검색어
    
    var selectedLatitude = 0.0      // 선택된 위도
    
    var selectedLongitude = 0.0     // 선택된 경도
    
    var selectedLocationName = ""   // 선택된 지명
    
    var org_cd = ""
    
    var delegate : SearchViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        
        print("넘어온 기기 >> \(org_cd)")
    }
    
    func searchLocation(){
        
        CSIndicator.shared.show(view)
        
        print("키워드 >> \(keyword)")
        
        let addr = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&language=ko&address=" + keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        print("조합된 주소 >> \(addr)")
        
        let url = URL(string: addr)!
        
        print("조회 주소 >> \(url)")
        
        Alamofire.request(url).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                
                let json = JSON(value)
                
                print("조회된 주소 >>> \(json)")
                
                CSIndicator.shared.hide()
                
                if json["status"].string! == "OK" {
                
                    if self.jsonArr.count < 0 {
                        self.jsonArr.removeAll()
                    }
                    self.jsonArr = json["results"].arrayValue
                    self.tbLocationList.reloadData()
                } else {
                    self.showAlert("조회된 내역이 없습니다!", "N")
                }

            case .failure(let error):
                
                self.showAlert(error.localizedDescription, "U")
                
                CSIndicator.shared.hide()
            }
        }

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
        
        if !FunctionClass.shared.isNullOrBlank(searchBar.text) {
            
            // 조회
            keyword = searchBar.text!
            
            searchLocation()
            
        } else {
            
            self.showAlert("검색어를 입력해주세요!", "N")
        
        }
    }
    
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
    
    func goToParrentView() {
        
        self.delegate?.searchViewControllerResponse(x: selectedLongitude, y: selectedLatitude, org_cd: org_cd, device_nm: selectedLocationName)
        
        self.navigationController?.popViewController(animated: true)
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)

        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        
        cell.textLabel?.text = FunctionClass.shared.isNullOrBlankReturn(jsonArr[indexPath.row]["formatted_address"].string)

        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedLatitude = jsonArr[indexPath.row]["geometry"]["location"]["lat"].double!
        selectedLongitude = jsonArr[indexPath.row]["geometry"]["location"]["lng"].double!
        selectedLocationName = jsonArr[indexPath.row]["formatted_address"].string!

        self.goToParrentView()
    }
    
}
