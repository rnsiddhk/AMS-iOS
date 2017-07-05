//
//  IssueViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 2..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class IssueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var tbIssueList: UITableView!
    
    @IBOutlet weak var tfJisa: UITextField!
    
    @IBOutlet weak var tfChannel: UITextField!
    
    @IBOutlet weak var tfStatus: UITextField!
    
    var refresh: UIRefreshControl!
    
    var issueList:[IssueCell] = [IssueCell]() // 커스텀 테이불 셀
    
    var jsonArr: Array<JSON> = []       // 데이터 통신 결과 JSON Array
    var jsonIssueList: Array<JSON> = [] // 데이터 통신 결과 JSON Array
    var json: JSON = []                 // 데아터 통신 결과 JSON
    var basicVO: BasicVO = BasicVO()    // 결과 저장 VO 클래스

    
    var statusList = Array<BasicVO>()   // 장애상태 리스트
    var jisaList = Array<BasicVO>()     // 지사 리스트
    var channelList = Array<BasicVO>()  // 채널 리스트
    var issueDataList = Array<BasicVO>() // 장애정보 리스트
    
    var selectedRowForSt: Int = -1   // 장애상태 선택 row
    var selectedRowForJs: Int = -1   // 지사구분 선택 row
    var selectedRowForCh: Int = -1   // 채널구분 선택 row
    var selectedRowForIs: Int = 0    // 선택한 데이터 row
    
    var selected_jisa: String = ""    // 선택한 지사 값
    var selected_ch: String = ""      // 선택한 채널 값
    var selected_st: String = ""      // 선택한 상태 값
    
    var PAGE_START: Int = 1           // 시작행
    var PAGE_END: Int = 25            // 마지막행
    
    // 기기등급 이미지
    var imageFileName = ["icon_grade_0.png", "icon_grade_1.png", "icon_grade_2.png",
                         "icon_grade_3.png", "icon_grade_4.png", "icon_grade_5.png",
                         "icon_grade_6.png", "icon_grade_7.png", "icon_grade_8.png",
                         "icon_grade_9.png", "icon_grade_10.png", "icon_grade_11.png"]
    
    var imageArray = [UIImage?]()
    
    var downGB: String = ""  // U:긴급 , I:장애
    
    var searchGB: String = "button" // button : CSIndicator , header : refreshControl
    
    var customView: UIView! // footer 영역 뷰
    
    var btn_footer: UIButton! // footer 버튼
    
    var isTop:Bool = false // pull to refresh 위치 확인
    
    var isViewAppear:Bool = false // 처음로딩시 자동 조회하기 위한 값
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // pull to refresh 하기 위해 테이블뷰에 셋팅하기
        refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: "Waiting...")
        refresh.addTarget(self, action: #selector(pullToRefresh), for: UIControlEvents.valueChanged)
        tbIssueList.refreshControl = refresh
        
        // 커스텀 footer 셋팅하기
        customView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        customView.backgroundColor = UIColor(red: 60/255, green: 177/255, blue: 73/255, alpha: 1)
        btn_footer = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        btn_footer.setTitle("더보기", for: .normal)
        btn_footer.addTarget(self, action: #selector(footerSearch), for: .touchUpInside)
        btn_footer.center = customView.center
        customView.addSubview(btn_footer)
        
        // 기기등급 이미지 초기화
        for i in 0 ..< imageFileName.count {
            let image = UIImage(named: imageFileName[i])
            imageArray.append(image)
        }
        
        initData()
        
        if downGB == "U" {
            self.navigationItem.title = "긴급출동"
        } else {
            self.navigationItem.title = "장애관리"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // 상세화면으로 이동해도 값을 가지고 있기 떄문에
        // 화면이 다시 보여졌을때 초기화 해야함
        selectedRowForSt = -1
        selectedRowForJs = -1
        selectedRowForCh = -1
        
        if 1 < self.statusList.count {
            tfStatus.text = self.statusList[1].data2
            self.selected_st = self.statusList[1].data1
        }
        
        if 1 < self.jisaList.count {
            tfJisa.text = self.jisaList[1].data2
            self.selected_jisa = self.jisaList[1].data1
            
            print("셋팅된 지사 코드 >> \(self.selected_jisa)")
            
            isViewAppear = true
            
            channelSearch()
        }
    }
    
    /* 초기 데이터 초기화 함수 */
    func initData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue("TR_STATUS", forKey: "gubun")
        
        http.paramBox.setValue("codeList", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("장애상태 코드 데이터 조회 성공 >> \(json)")
                self.setCodeData(json)
            case .failure(let error) :
                print("장애상태 코드 데이터 조회 실패 >> \(error.localizedDescription)")
                CSIndicator.shared.hide()
            }
        }
    }
    
    /* 장애코드 셋팅 함수 */
    func setCodeData(_ resJson: JSON){

        jsonArr = resJson["codeList"]["list"].arrayValue
        
        basicVO = BasicVO()
        basicVO.data1 = "NO"
        basicVO.data2 = "-선택-"
        statusList.append(basicVO)
        
        for i in 0 ..< jsonArr.count {
            
            basicVO = BasicVO()
            json = jsonArr[i]
 
            if json["ITEM1"].string == "-1" {
                basicVO.data1 = "NOT_TREATED_ALL"
                basicVO.data2 = json["ITEM2"].string!
            } else {
                
                if i == 1 {
                    basicVO.data1 = "ALL"
                    basicVO.data2 = "전체"
                    
                    statusList.append(basicVO)
                    
                    basicVO = BasicVO()
                    
                    basicVO.data1 = json["ITEM1"].string!
                    basicVO.data2 = json["ITEM2"].string!

                } else {
                    basicVO.data1 = json["ITEM1"].string!
                    basicVO.data2 = json["ITEM2"].string!
                }
            }
            
            statusList.append(basicVO)
        }
        
        print("상태값 총 갯수 \(statusList.count)")
        
        self.jisaSearch()
    }
    
    /* 지사코드 조회 함수 */
    func jisaSearch(){
        
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
        self.channelSearch()
    }
    
    /* 채널 코드 조회 함수 */
    func channelSearch(){
        
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
        
        if 0 < self.statusList.count {
            
            createPicker(tfStatus, 200)
        }
        
        if 0 < self.jisaList.count {
            
            createPicker(tfJisa, 300)
        }
        
        if 0 < self.channelList.count {
            
            createPicker(tfChannel, 400)
        }
        
        CSIndicator.shared.hide()
        
        if isViewAppear {
            
            if 1 < self.channelList.count {
                tfChannel.text = self.channelList[1].data2
                selected_ch = self.channelList[1].data1
                isTop = true
                searchIssueList()
            }

        }
        
    }
    
    /* pull to refresh 함수 */
    func pullToRefresh(){
        
        isTop = true
        
        print("refresh 호출")
        PAGE_START = 1
        PAGE_END = 25
        searchGB = "header"
        searchIssueList()
        
    }
    
    /* footer 함수 */
    func footerSearch(){
        
        isTop = false
        
        print("footerSearch 호출")
        
        PAGE_START = PAGE_END + 1
        PAGE_END = PAGE_END + 25
        searchGB = "button"
        searchIssueList()
        
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
            
            if -1 < self.selectedRowForSt {
                
                if self.selectedRowForSt  != 0 {
                    tfStatus.text = self.statusList[self.selectedRowForSt].data2
                    self.selected_st = self.statusList[self.selectedRowForSt].data1
                }
            }
            if -1 < self.selectedRowForJs {
                
                if self.selectedRowForJs != 0 {
                    tfJisa.text = self.jisaList[self.selectedRowForJs].data2
                    self.selected_jisa = self.jisaList[self.selectedRowForJs].data1
                    print("선택된 지사 코드 \(self.selected_jisa)")
                    
                    isViewAppear = false
                    
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
        
        // 키보드 내리기
        tfStatus.resignFirstResponder()
        tfJisa.resignFirstResponder()
        tfChannel.resignFirstResponder()
    }
    
    @IBAction func btnSearchAction(_ sender: UIButton) {
        
        isTop = true
        isViewAppear = false
        searchGB = "button"
        PAGE_START = 1
        PAGE_END = 25
        
        searchIssueList()
    }
    
    /* 긴급/장애 조회 함수 */
    func searchIssueList(){
        
        if searchGB == "button" {
            CSIndicator.shared.show(view)
        } else {
            refresh.beginRefreshing()
        }

        let http = HttpRequest(option: "data")
        
        if downGB == "U" {
            http.paramData.setValue("1", forKey: "down_gb")     // 장애구분 긴급 : 1, 장애 : 0
        } else {
            http.paramData.setValue("0", forKey: "down_gb")
        }
        
        http.paramData.setValue("", forKey: "org_cd")           // 기기번호
        
        http.paramData.setValue(selected_st, forKey: "treat_status")    // 처리상태
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id") // 사용자 아이디
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group") // 시용자 그룹
        http.paramData.setValue(selected_jisa, forKey: "branch_gb") // 지사구분
        http.paramData.setValue(selected_ch, forKey: "team_gb")     // 채널구분
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ENT"), forKey: "user_ent") // 업체 구분
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade") // 사용자 직책
        http.paramData.setValue(PAGE_START, forKey: "startRow") // 시작행
        http.paramData.setValue(PAGE_END, forKey: "endRow")     // 마지막행
        
        http.paramBox.setValue("obstacle", forKey: "method")    // API 메소드명
        http.paramBox.setValue(http.paramData, forKey: "params")// parameter
        
        http.paramArray.add(http.paramBox)
        
        print("장애 리스트 매개변수 값. >> \(http.paramBox.value(forKey: "params")!)")
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                self.setIssueDataList(json)
            case .failure(let error) :
                print("장애 리스트 조회 실패 >> \(error.localizedDescription)")
                
                if self.searchGB == "button" {
                    CSIndicator.shared.hide()
                } else {
                    self.refresh.endRefreshing()
                }
            }
        }
    }
    
    /* 긴급/장애 조회 셋팅 함수 */
    func setIssueDataList(_ resJson: JSON){
    
        jsonIssueList = resJson["obstacle"]["list"].arrayValue
        
        // pull to refresh 인 경우 데이터 리스트 객체 초기화
        if isTop {
            issueDataList.removeAll()
        }
        
        for i in 0..<jsonIssueList.count{

            basicVO = BasicVO()
            
            basicVO.data1 = jsonIssueList[i]["ATM_NM"].string!              // 기기명
            basicVO.data2 = jsonIssueList[i]["DOWN_ATM_NM"].string!         // 장애명
            basicVO.data3 = jsonIssueList[i]["ATM_GRADE"].string!           // 기기등급
            basicVO.data4 = String(describing:jsonIssueList[i]["TREAT_STEP"].int!) // 장애처리 스텝
            basicVO.data5 = jsonIssueList[i]["TREAT_STATUS"].string!        // 조치상태
            basicVO.data6 = jsonIssueList[i]["TREAT_STATUS_NM"].string!     // 조치상태명
            basicVO.data7 = jsonIssueList[i]["GIJUN_IL"].string!            // 장애발생일
            basicVO.data8 = jsonIssueList[i]["ORG_CD"].string!              // 기기번호
            basicVO.data9 = jsonIssueList[i]["DOWN_SI"].string!             // 장애발생시간
            basicVO.data10 = jsonIssueList[i]["DOWN_GB"].string!            // 장애구분

            issueDataList.append(basicVO)
        }
        
        // 조회된 결과의 갯수가 25개인 경우 페이징처리 하기 위해 footer 셋팅
        if resJson["obstacle"]["list"].arrayValue.count == 25 {
            tbIssueList.tableFooterView = customView
        } else {
            tbIssueList.tableFooterView = nil
        }
        
        // 조회 버튼/footer로 조회가 실행할 경우 Indicator 숨기기
        // pull to refresh인 경우 refreshControl 끝내기
        if self.searchGB == "button" {
            CSIndicator.shared.hide()
        } else {
            self.refresh.endRefreshing()
        }
        
        // 테이블뷰 데이터 리로딩
        self.tbIssueList.reloadData()
    }

    /* TableView DataSource */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    /* TableView DataSource */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issueDataList.count
    }
    

    /* TableView Delegate */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "IssueCell", for: indexPath) as! IssueCell

        cell.lblDevice.text = issueDataList[indexPath.row].data1 + " (" + issueDataList[indexPath.row].data2 + ")"
        
        cell.imgGrade.image = imageArray[Int(issueDataList[indexPath.row].data3)!]
        
        cell.lblStatus.text = issueDataList[indexPath.row].data4 + "차 " + issueDataList[indexPath.row].data6
        
        cell.lblStatus.textColor = UIColor.white
        
        cell.lblStatus.layer.cornerRadius = 10
        cell.lblStatus.clipsToBounds = true
        cell.lblStatus.layer.masksToBounds = true
        
        if issueDataList[indexPath.row].data6 == "신규" {
            // 파랑색
            cell.lblStatus.backgroundColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        } else if issueDataList[indexPath.row].data6 == "접수" {
            // 녹색
            cell.lblStatus.backgroundColor = UIColor(red: 0, green: 128/255, blue: 0, alpha: 1)
        } else if issueDataList[indexPath.row].data6 == "도착" {
            // 분홍색
            cell.lblStatus.backgroundColor = UIColor(red: 255, green: 182/255, blue: 193/255, alpha: 1)
        } else if issueDataList[indexPath.row].data6 == "이관" {
            // 주황색
            cell.lblStatus.backgroundColor = UIColor(red: 255, green: 162/255, blue: 0, alpha: 1)
        } else {
            // 밝은 회색
            cell.lblStatus.backgroundColor = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedRowForIs = indexPath.row
        
        self.performSegue(withIdentifier: "segIssueDt", sender: nil)
    }
    
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
    /* PickerView DataSource */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /* PickerView DataSource */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.tag == 200 {
            return statusList.count
        }else if pickerView.tag == 300 {
            return jisaList.count
        } else {
            return channelList.count
        }
    }
    
    /* PickerView Delegate */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if pickerView.tag == 200 {
            return statusList[row].data2
        }else if pickerView.tag == 300 {
            return jisaList[row].data2
        } else {
            return channelList[row].data2
        }
    }
    
    /* PickerView Delegate */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 200 {
            selectedRowForSt = row
        }else if pickerView.tag == 300 {
            selectedRowForJs = row
        } else {
            selectedRowForCh = row
            print("선택한 row >> \(row)")
        }
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "segIssueDt" {
            let destination = segue.destination as! IssueDtViewController
            destination.treat_status = issueDataList[selectedRowForIs].data5
            destination.gijun_il = issueDataList[selectedRowForIs].data7
            destination.org_cd = issueDataList[selectedRowForIs].data8
            destination.down_si = issueDataList[selectedRowForIs].data9
            destination.down_gb = issueDataList[selectedRowForIs].data10
        }
    }

}
