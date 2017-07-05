//
//  IssueDtViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 8..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MobileCoreServices

class IssueDtViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblDeviceNM: UILabel!
    
    @IBOutlet weak var lblDeviceNo: UILabel!
    
    @IBOutlet weak var imgGrade: UIImageView!
    
    @IBOutlet weak var lblIssueTime: UILabel!
    
    @IBOutlet weak var lblIssueSt: UILabel!
    
    @IBOutlet weak var lblTel: UILabel!
    
    @IBOutlet weak var txtRequest: UITextView!
    
    @IBOutlet weak var txtLocation: UITextView!
    
    @IBOutlet weak var tbRepairList: UITableView!
    
    @IBOutlet weak var tfTime: UITextField!
    
    @IBOutlet weak var tfResult: UITextField!
    
    @IBOutlet weak var tfCampany: UITextField!
    
    @IBOutlet weak var txtRepairMemo: UITextView!
    
    @IBOutlet weak var lblCompany: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var btnTime: BasicButton!
    
    @IBOutlet weak var btnRegist: BasicButton!
    
    @IBOutlet weak var btnGoodsInfo: BasicButton!
    
    @IBOutlet weak var btnCamera: BasicButton!
    
    @IBOutlet weak var btnCameraRoll: BasicButton!
    
    @IBOutlet weak var btnDelete: BasicButton!
    
    
    var jsonArr: Array<JSON> = []
    var json: JSON = []
    
    let timePoint:[String] =  ["15분", "30분", "1시간", "2시간", "2시간 이상"]    // 도착예정시간
    let resultArr:[String] =  ["완료", "미완료(이관)"]     // 처리결과
    var companyArr:[String] = []                       // 이관업체
    
    var selectedTime: Int = 0       // 0:15분, 1:30분, 2:1시간, 4:2시간 이상
    var selectedRes: Int = 0
    var selectedCom: Int = 0
    
    var repairList:[String] = []    // 조치사항 리스트
    var treat_status: String = ""   // 조치상태
    var gijun_il: String = ""       // 기준일
    var org_cd: String = ""         // 기기번호
    var down_si: String = ""        // 장애발생시간
    var down_gb: String = ""        // 장애구분
    var repair_il: String = ""      // 조치일
    var repair_si: String = ""      // 조치시간
    
    var timeChange: Bool = false    // 시간변경 플래그
    var treatStatus: Int = 0        // 조치상태값 0:신규, 1:접수, 2:이관, 3:도착, 8:자동복구, 9:처리완료
    var treatStep: String = ""      // 조치 차수
    var repairMemo: String = ""     // 조치내역 메모
    let TR_NM: [Int:String] = [1:"접수완료", 2:"이관", 3:"현장도착", 8:"자동복구", 9:"처리완료"]  // 조치내역 map

    var customView: UIView!         // footer 영역 뷰
    
    var btn_footer: UIButton!       // footer 버튼
    
    var newMedia: Bool = false      // 이미지 플래그
    
    var imgFileNm: String = ""      // 이미지 이름
    
    let dateFormatter = DateFormatter()
    
    var imageVO = BasicVO()
    
    var x_grid = 0.0                // 경도
    
    var y_grid = 0.0                // 위도
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        

        print("넘어온 값 >> \(gijun_il) >> \(org_cd) >> \(down_si) >> \(down_gb) >> \(treat_status)")
        
        self.navigationItem.title = "상세화면"
        
        scrollView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        scrollView.addGestureRecognizer(tapGesture)
        
        print("TR_NM >> \(TR_NM[1]!)")
        
        if UserDefaults.standard.string(forKey: "USER_GRADE") == "7" ||
            UserDefaults.standard.string(forKey: "USER_GRADE") == "9" ||
            UserDefaults.standard.string(forKey: "USER_GRADE") == "99"
            {
            btnGoodsInfo.isEnabled = false
        }
        
        dateFormatter.dateFormat = "yyyMMddHHmmss"
        
        self.initData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 옵저버 설정
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 옵저버 해제
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillShow,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIKeyboardWillHide,
                                                  object: nil)
    }
    
    // 스크롤뷰 탭 제스쳐 함수
    func btnTapped(sender: UITapGestureRecognizer){
        
        self.view.endEditing(true)
    }
    
    // 키보드 show 함수
    func keyboardWillShow(_ notification: Notification){
        
        guard notification.userInfo != nil else {
            return
        }
        
        self.view.frame.origin.y -= 180
        
    }
    
    // 키보드 hide 함수
    func keyboardWillHide(_ notification: Notification){
        
        self.view.frame.origin.y = 0
    }
    
    func initData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        // 테스트용
//        http.paramData.setValue("20170515", forKey: "gijun_il") // 장애발생일
//        http.paramData.setValue("10417086", forKey: "org_cd")   // 기기번호
//        http.paramData.setValue("150206", forKey: "down_si")  // 장애발생시간
//        http.paramData.setValue("0", forKey: "down_gb")  // 장애구분
        
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il") // 장애발생일
        http.paramData.setValue(org_cd, forKey: "org_cd")   // 기기번호
        http.paramData.setValue(down_si, forKey: "down_si")  // 장애발생시간
        http.paramData.setValue(down_gb , forKey: "down_gb")  // 장애구분
        
        http.paramBox.setValue("dscOb", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            print(response.result)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                print("장애 상세 화면 데이터 조회 성공 >> \(json)")
                
                if 0 < json["dscOb"].count {
                    self.setData(json)
                } else {
                    CSIndicator.shared.hide()
                    self.showAlert("조회된 내용이 없습니다!", "U")
                }
 
            case .failure(let error) :
                print("장애 상세 화면 데이터 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "U")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setData(_ resJson: JSON){
        
        // 경도
        if resJson["dscOb"]["info"]["X_GRID"].double != nil {
            x_grid = resJson["dscOb"]["info"]["X_GRID"].double!
        }
        
        // 위도
        if resJson["dscOb"]["info"]["Y_GRID"].double != nil {
            y_grid = resJson["dscOb"]["info"]["Y_GRID"].double!
        }
        
        // 기기명
        lblDeviceNM.text = resJson["dscOb"]["ATM_NM"].string
        
        // 기기번호
        lblDeviceNo.text = resJson["dscOb"]["ORG_CD"].string
        
        let imageGrade = ("icon_grade_" + resJson["dscOb"]["ATM_GRADE"].string! + ".png")
        
        // 기기등급
        imgGrade.image = UIImage(named: imageGrade)

        // 발생시간
        lblIssueTime.text = resJson["dscOb"]["DOWN_TIME"].string
        
        // 장애유형
        lblIssueSt.text = resJson["dscOb"]["DOWN_ATM_NM"].string
        
        // 연락처
        lblTel.text = resJson["dscOb"]["ERR_TEL"].string
        
        // 요청사항
        txtRequest.text = resJson["dscOb"]["DOWN_MEMO"].string
        
        // 기기 위치
        txtLocation.text = resJson["dscOb"]["ADDR_RMK"].string
        
        // 조치 차수
        treatStep = String(describing: resJson["dscOb"]["TREAT_STEP"].int!)
        
        // 이관업체 정보 셋팅
        companyArr.append("장애(주간) : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["DAY_ADMIN_NM"].string))
        
        companyArr.append("장애(야간) : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["NIGHT_ADMIN_NM"].string))
        
        companyArr.append("회선 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["LINE_ENT_NM"].string))
        
        companyArr.append("부스 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["BOOTH_MAKER_NM"].string))
        
        companyArr.append("간판 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["SIGN_ENT_NM"].string))
        
        companyArr.append("생산 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["ATM_MAKER_NM"].string))
        
        companyArr.append("채널개발 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["ATM_SPIC_NM"].string))
        
        companyArr.append("보안 : " + FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["info"]["SECURE_ENT_NM"].string))
        
        createPicker(tfTime, 100)
        
        createPicker(tfResult, 200)
        
        createPicker(tfCampany, 300)
        
        jsonArr = resJson["dscOb"]["list"].arrayValue
        
        for i in 0 ..< jsonArr.count {
            
            json = jsonArr[i]
            
            repairList.append(FunctionClass.shared.isNullOrBlankReturn(json["REPAIR_TIME"].string) + " " + FunctionClass.shared.isNullOrBlankReturn(json["REPAIR_REG_NM"].string) + " " + FunctionClass.shared.isNullOrBlankReturn(json["REPAIR_MEMO"].string))
        }
        
        // 조치내역 테이블뷰 리로딩
        tbRepairList.reloadData()
        
        // 조회된 도착예정 시간으로 PickerView 셋팅
        // nil 체크
        let time  = FunctionClass.shared.isNullOrBlankReturn(resJson["dscOb"]["P_ARR_TIME"].string)
        
        // 공백인 경우 첫번째 인자 값 선택
        // 값이 있는 경우 해당되는 값으로 선택
        if time == "" {
            tfTime.text = timePoint[0]
            selectedTime = 0
        } else {
            let setTime = Int(time)
            tfTime.text = timePoint[setTime!]
            selectedTime = setTime!
        }
        
        // 처리결과 PickerView 첫번째 값 셋팅
        tfResult.text = resultArr[0]
        selectedRes = 0
        
        // 이관업체 PickerView 첫번째 값 셋팅
        tfCampany.text = companyArr[0]
        selectedCom = 0
        
        lblCompany.isHidden = true
        tfCampany.isHidden = true
        
        btnTime.isHidden = true
        tfResult.isEnabled = false
        txtRepairMemo.isEditable = false

        
        if treat_status == "1" {
            
            btnTime.isHidden = false
            btnRegist.setTitle("도착", for: .normal)
            
        } else if treat_status == "3" {
            
            tfTime.isEnabled = false
            tfResult.isEnabled = true
            txtRepairMemo.isEditable = true
            btnTime.isHidden = true
            btnRegist.setTitle("저장", for: .normal)
            treatStatus = 9
            
        } else if treat_status == "9" {
            
            tfTime.isEnabled = false
            btnRegist.isHidden = true
            
            // 커스텀 footer 셋팅하기
            customView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
            customView.backgroundColor = UIColor(red: 60/255, green: 177/255, blue: 73/255, alpha: 1)
            btn_footer = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
            btn_footer.setTitle("조치내역 수정", for: .normal)
            btn_footer.addTarget(self, action: #selector(footerAction), for: .touchUpInside)
            btn_footer.center = customView.center
            customView.addSubview(btn_footer)
            
            tbRepairList.tableFooterView = customView

        }
        
        if 0 < repairList.count  {
            
            let indexPath = IndexPath(row: repairList.count-1, section: 0)
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tbRepairList.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }

        }
        
        // 사진첨부 사용 버튼 비활성화
        btnCamera.isEnabled = false
        btnCameraRoll.isEnabled = false
        btnDelete.isEnabled = false
        
        CSIndicator.shared.hide()
    }
    
    func footerAction(){
        
        tfResult.isEnabled = true
        txtRepairMemo.isEditable = true
        btnRegist.isHidden = false
        btnRegist.setTitle("수정", for: .normal)
        
        var offset = scrollView.contentOffset
        
        offset.y = scrollView.contentSize.height + scrollView.contentInset.bottom - scrollView.bounds.size.height
        scrollView.setContentOffset(offset, animated: true)
    
    }
    
    // 지도보기
    @IBAction func btnMap(_ sender: UIButton) {
        
        self.performSegue(withIdentifier: "segLocationMap", sender: nil)
    }
    
    // 경로보기
    @IBAction func btnRoute(_ sender: UIButton) {
        
        // 좌표가 없을 경우 처리
        if x_grid == 0.0 || y_grid == 0.0 {
            self.showAlert("기기의 좌표 정보가 없습니다.", "N")
        } else {
            self.performSegue(withIdentifier: "segRouteMap", sender: nil)
        }
    }
    
    
    @IBAction func btnGoodsInfo(_ sender: UIButton) {
        
        let passAlert = UIAlertController(title: "2차 비밀번호", message: "", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { (_) in
            let textField = passAlert.textFields![0]
            print(textField.text!)
            self.confirmPass(textField.text!)
        }
        let cancelAtion = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        passAlert.addTextField { (textField: UITextField) in
            textField.keyboardAppearance = .default
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
            textField.placeholder = "비밀번호 입력"
            textField.textAlignment = .center
        }
        passAlert.addAction(okAction)
        passAlert.addAction(cancelAtion)
        
        present(passAlert, animated: true, completion: nil)
    }
    
    // 2차 패스워드 확인 함수
    func confirmPass(_ pass: String){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")   // 기기번호
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id") // 사용자 아이디
        http.paramData.setValue(pass, forKey: "second_pw")  // 2차 패스워드
        http.paramData.setValue("00", forKey: "job_type")   // job 구붖 = 00: 시재정보 조회, 10:OTP 조회
        
        
        http.paramBox.setValue("auth", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        print("2차 패스워드 매개변수 값. >>\(http.paramBox.value(forKey: "params")!)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print("2차 패스워드 성공 >> \(json)")
                self.setConfirmPass(json)
                
            case .failure(let error) :
                print("2차 패스워드 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    // 2차 패스워드 결과정리 함수
    func setConfirmPass(_ resJson: JSON){
        
        CSIndicator.shared.hide()
        
        if resJson["auth"]["code"].int! == 0 {
            self.performSegue(withIdentifier: "segGoods", sender: nil)
        } else {
            self.showAlert("패스워드를 확인해주세요!", "N")
        }
    }
    
    // 사진첨부 함수
    @IBAction func btnAddImage(_ sender: UIButton) {
        
        if treatStatus == 2  || treatStatus == 9 {
            btnCamera.isEnabled = true
            btnCameraRoll.isEnabled = true
            btnDelete.isEnabled = true
        } else {
            self.showAlert("완료 및 이관 업무시에\n사진을 업로드 할 수 있습니다!", "N")
        }
    }
    
    // 카메라
    @IBAction func useCameraAction(_ sender: UIButton){
        
        newMedia = true
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    // 카메라롤
    @IBAction func useCameraRollAction(_ sender: UIButton){
        
        newMedia = false
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // 이미지 삭제 함수
    @IBAction func cancelImage(_ sender: UIButton){
        
        newMedia = false
        
        imageView.image = nil
        
        imgFileNm = ""
        imageVO.data1 = ""
        imageVO.data2 = ""
    
    }
    
    // 취소
    @IBAction func cancelAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    // 시간변경
    @IBAction func timeAction(_ sender: UIButton) {
        timeChange = true
        treatStatus = 1
        updateTime()
    }
    // 저장/도착
    @IBAction func saveAction(_ sender: UIButton) {
        
        
        // 버튼 라벨에 따라 처리 상태값 변경
        if btnRegist.titleLabel?.text == "접수" {
            treatStatus = 1
        } else if btnRegist.titleLabel?.text == "도착" {
            treatStatus = 3
        }
        
        // 이관, 완료 내용처리
        if treatStatus == 2 || treatStatus == 9 {
            repairMemo = txtRepairMemo.text.trimmingCharacters(in: .whitespaces)
            
            if repairMemo != "" {
                print("메모 내용 출력 >> \(repairMemo)")
                inputData()
            } else {
                print("조치내역 입력 >> 확인 필요")
                self.showAlert("조치내역 입력", "N")
            }
        } else {
            inputData()
        }
    }
    
    // 장애조치내역 API 서버 통신 함수
    func inputData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il")   // 장애발생일
        http.paramData.setValue(org_cd, forKey: "org_cd")       // 기기번호
        http.paramData.setValue(down_si, forKey: "down_si")     // 장애발생시간
        http.paramData.setValue(down_gb, forKey: "down_gb")     // 장애구분
        http.paramData.setValue(String(describing: treatStatus), forKey: "treat_status")     // 처리상태구분
        http.paramData.setValue(treatStep, forKey: "treat_step")// 처리 차수
        http.paramData.setValue(selectedTime, forKey: "p_arr_time")// 도착예정 시간
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_NM"), forKey: "repair_reg_nm")// 접수자명
        
        // 접수, 도착의 상태를 구분하여 접수 메모 값 셋팅
        if treatStatus == 1 || treatStatus == 3 {
            http.paramData.setValue(TR_NM[treatStatus]!, forKey: "repair_memo")// 조치메모
        } else {
            http.paramData.setValue(repairMemo, forKey: "repair_memo")
        }
        
        /* 이미지 업로드시 사용할 예정
         테스트 서버에서 사용 불가 */
         if imgFileNm != "" {
            http.paramData.setValue(imgFileNm, forKey: "photo_nm")// 이미지 파일 이름
         }
        
        http.paramData.setValue(timeChange, forKey: "change_p_arr_time")// 도착시간 변경 플래그
        
        http.paramBox.setValue("updateOb", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        print("장애 접수 매개변수 값. >>\(http.paramBox.value(forKey: "params")!)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print("장애 접수 성공 >> \(json)")
                self.setInputData(json)

            case .failure(let error) :
                print("장애 조치 접수 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    // 장애조치사항 API 서버통신 결과 정리 함수
    func setInputData(_ resJson: JSON){
        
        CSIndicator.shared.hide()
        
        var msg: String = ""
        
        // 성공
        if resJson["updateOb"]["code"].int! == 0 {
            
            
            if treatStatus == 9 || treatStatus == 2 {
                repair_il = resJson["updateOb"]["repair_il"].string!
                repair_si = resJson["updateOb"]["repair_si"].string!
            }
            
            // 첨부할 이미지가 있을 경우 이미지 업로드 함수 호출
            if imgFileNm != "" {
                uploadImage()
            }else{
                msg = TR_NM[treatStatus]! + " 처리가 정상적으로 되었습니다."
                showAlert(msg, "U")
            }

        } else {
            msg = TR_NM[treatStatus]! + " 처리가 되지 않았습니다."
            showAlert(msg, "U")
        }
    }
    
    // 시간변경 함수
    func updateTime(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il")   // 장애발생일
        http.paramData.setValue(org_cd, forKey: "org_cd")       // 기기번호
        http.paramData.setValue(down_si, forKey: "down_si")     // 장애발생시간
        http.paramData.setValue(down_gb, forKey: "down_gb")     // 장애구분
        http.paramData.setValue(String(describing: treatStatus), forKey: "treat_status")     // 처리상태구분
        http.paramData.setValue(selectedTime, forKey: "p_arr_time")// 도착예정 시간
        http.paramData.setValue(timeChange, forKey: "change_p_arr_time")// 도차시간 변경 플래그
        
        
        http.paramBox.setValue("arrival", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        print("도착시간 변경 매개변수 값. >>\(http.paramBox.value(forKey: "params")!)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print("도착시간 변경 성공 >> \(json)")
                self.setUpdateTime(json)
                
            case .failure(let error) :
                print("도착시간 변경 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    // 시간변경 결과 처리 함수
    func setUpdateTime(_ resJson: JSON){
        CSIndicator.shared.hide()
        
        var msg: String = ""
        
        // 성공
        if resJson["arrival"]["code"].int! == 0 {
            msg = "도착 예정시간이 변경 되었습니다."
        } else {
            msg = "도착 예정시간이 변경 되지 않았습니다."
        }
        
        showAlert(msg, "U")
    }
    
    
    // 이미지 업로드 함수
    func uploadImage(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "image")
        
        http.paramData.setValue(gijun_il, forKey: "gijun_il")     // 장애발생일
        http.paramData.setValue(org_cd, forKey: "org_cd")         // 기기번호
        http.paramData.setValue(down_si, forKey: "down_si")       // 장애발생시간
        http.paramData.setValue(down_gb, forKey: "down_gb")       // 장애구분
        http.paramData.setValue(repair_il, forKey: "repair_il")   // 조치일
        http.paramData.setValue(repair_si, forKey: "repair_si")   // 조치시간
        http.paramData.setValue(imgFileNm, forKey: "photo_nm")    // 사진이름
        http.paramData.setValue(imageVO.data1, forKey: "original")// 원본 이미지
        http.paramData.setValue(imageVO.data2, forKey: "thumb")   // 썸네일 이미지
        http.paramData.setValue("FAIL", forKey: "type")           // type : 이슈/장애관리 -> FAIL, 상태관리 -> STATE

        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramData, options: [])
        
//        print("업로드 이미지 전송 파라메터 >> \(http.paramData)")
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print(json)
                self.setUploadImage(json)
            case .failure(let error) :
                print("이미지 등록 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    // 이미지 업로드 결과 처리 함수
    func setUploadImage(_ resJson: JSON){
        
        var msg: String
        
        // 등록 성공 확인
        if resJson["code"].string! == "0" {
            msg = TR_NM[treatStatus]! + " 처리 성공!\n이미지 등록이 정상적으로 되었습니다."
        } else {
            msg = TR_NM[treatStatus]! + " 처리 성공!\n이미지 등록이 되지 않았습니다."
        }
        
        showAlert(msg, "U")
        CSIndicator.shared.hide()
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
    
    func createPicker(_ textField : UITextField, _ tagId: Int){
        
        let pv = UIPickerView()
        
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
    
    func doneButton(sender: UIBarButtonItem){
        
        if sender.title == "완료" {
            
            if -1 < selectedTime {
                tfTime.text = timePoint[selectedTime]
            }
            
            if -1 < selectedRes {
                tfResult.text = resultArr[selectedRes]
                
                // 완료
                if selectedRes == 0 {
                    treatStatus = 9
                    lblCompany.isHidden = true
                    tfCampany.isHidden = true
                } else {    // 이관
                    treatStatus = 2
                    lblCompany.isHidden = false
                    tfCampany.isHidden = false
                }
            }
            
            if -1 < selectedCom {
                
                tfCampany.text = companyArr[selectedCom]
                
                // 이관을 선택하였을 시 조치내역에 이관 업체의 정보를 셋팅
                if selectedRes != 0 {
                    txtRepairMemo.text = companyArr[selectedCom]
                } else {
                    txtRepairMemo.text = ""
                }

            }
        }
        
        tfTime.resignFirstResponder()
        tfResult.resignFirstResponder()
        tfCampany.resignFirstResponder()
    
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.tag == 100 {
        return timePoint.count
        } else if pickerView.tag == 200 {
            return resultArr.count
        } else {
            return companyArr.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView.tag == 100 {
            return timePoint[row]
        } else if pickerView.tag == 200 {
            return resultArr[row]
        } else {
            return companyArr[row]
        }

    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView.tag == 100 {
            selectedTime = row
        } else if pickerView.tag == 200 {
            selectedRes = row
        } else {
            selectedCom = row
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repairList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "repairCell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = repairList[indexPath.row]
        
        return cell
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        self.dismiss(animated: true, completion: nil)
        
        print("카메라! 여기 타니?")
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // 원본이미지 NSData
        let imageData: NSData = UIImageJPEGRepresentation(image, 0.4)! as NSData
        
        // 썸네일 NSData
        let imageThumbData: NSData = UIImageJPEGRepresentation(FunctionClass.shared.thumbnailImage(image), 0.4)! as NSData
        let thumbImage = FunctionClass.shared.thumbnailImage(image)
        
        imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
        
        imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
        imageView.image = thumbImage
        
        // 전송 이미지 파일 이름 명명 규칙
        // yyyyMMddHHmmss-기기번호(8)사번(8).jpg
        let today = Date()
        let userId: String = UserDefaults.standard.string(forKey: "USER_ID")!
        
        imgFileNm = dateFormatter.string(from: today) + "-" + org_cd + userId + ".jpg"

        print("생성된 이미지 파일 이름 >> \(imgFileNm)")
        
        // 2017.05.08 JJH -> 이미지 전송 후 사진 저장 로직 들어가야 함
        if newMedia {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }

    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        print("여기까지 오나요??")
        
        // 기기정보
        if segue.identifier == "segAtmInfo" {
            
            let destination = segue.destination as! AtmInfoController
            destination.org_cd = org_cd
            
        } else if segue.identifier == "segIssueHIS"{    // 장애이력
            
            let destination = segue.destination as! IssueHISViewController
            destination.org_cd = org_cd
            
        } else if segue.identifier == "segGoods"{   // 시재정보
            
            let destination = segue.destination as! GoodsInfoViewController
            destination.org_cd = org_cd
            
        }else if segue.identifier == "segLocationMap"{   // 지도보기
            
            let destination = segue.destination as! GoogleMapViewController
            destination.xGrid = x_grid
            destination.yGrid = y_grid
            destination.viewName = "POINT"
            destination.org_cd = org_cd
            destination.deviceName = lblDeviceNM.text!
            
        } else if segue.identifier == "segRouteMap"{     // 경로보기
            
            let destination = segue.destination as! GoogleMapViewController
            destination.xGrid = x_grid
            destination.yGrid = y_grid
            destination.viewName = "ROUTE"
            destination.deviceName = lblDeviceNM.text!
            
        }
    }
}
