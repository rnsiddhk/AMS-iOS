//
//  StatusMgrDtViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 5. 23..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MobileCoreServices

class StatusMgrDtViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblDeviceNm: UILabel!
    
    @IBOutlet weak var lblDeviceNo: UILabel!
    
    @IBOutlet weak var imgGrade: UIImageView!
    
    @IBOutlet weak var lblDownTime: UILabel!
    
    @IBOutlet weak var lblDownStatus: UILabel!
    
    @IBOutlet weak var lblJisa: UILabel!
    
    @IBOutlet weak var txtLocation: UITextView!
    
    @IBOutlet weak var lblIssueDS: UILabel!
    
    @IBOutlet weak var lblImage01: UILabel!
    
    @IBOutlet weak var lblImage02: UILabel!
    
    @IBOutlet weak var lblImage03: UILabel!
    
    @IBOutlet weak var lblImage04: UILabel!
    
    @IBOutlet weak var lblImage05: UILabel!
    
    @IBOutlet weak var lblImage06: UILabel!
    
    @IBOutlet weak var lblImage07: UILabel!
    
    @IBOutlet weak var lblImage08: UILabel!
    
    @IBOutlet weak var imgDevice01: UIImageView!
    
    @IBOutlet weak var imgDevice02: UIImageView!
    
    @IBOutlet weak var imgDevice03: UIImageView!
    
    @IBOutlet weak var imgDevice04: UIImageView!
    
    @IBOutlet weak var imgDevice05: UIImageView!
    
    @IBOutlet weak var imgDevice06: UIImageView!
    
    @IBOutlet weak var imgDevice07: UIImageView!
    
    @IBOutlet weak var imgDevice08: UIImageView!
    
    @IBOutlet weak var btnImage01: UIButton!
    
    @IBOutlet weak var btnImage02: UIButton!
    
    @IBOutlet weak var btnImage03: UIButton!
    
    @IBOutlet weak var btnImage04: UIButton!
    
    @IBOutlet weak var btnImage05: UIButton!
    
    @IBOutlet weak var btnImage06: UIButton!
    
    @IBOutlet weak var btnImage07: UIButton!
    
    @IBOutlet weak var btnImage08: UIButton!
    
    @IBOutlet weak var tfStatus: UITextField!
    
    @IBOutlet weak var txtMemo: UITextView!
    
    var org_cd: String = ""
    
    var x_grid: Double = 0.0
    
    var y_grid: Double = 0.0
    
    var statusArr: [String] = ["선택", "간판점검", "부스청소", "기기청소", "누진점검", "기기내부청소", "기타"]
    
    var selectedSt: Int = 0
    
    var currentImage: Int = 0
    
    var newMedia: Bool = false
    
    var imgCnt: Int = 0
    
    var IMG_CNT: Int = 8
    
    var repair_memo: String = ""
    
    var imageList = Array<BasicVO>()
    
    var imageVO = BasicVO()
    
    var imageMap = [Int:BasicVO]()
    

    var oldeContentInset = UIEdgeInsets.zero
    var oldIndicatorInset = UIEdgeInsets.zero
    var oldOffset = CGPoint.zero
    var keyboardShowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.title = "상태관리 상세"
        
        scrollView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        scrollView.addGestureRecognizer(tapGesture)
        
        initData()

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
        
        print("넘어온 기기 번호. >> \(org_cd)")
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")
        http.paramBox.setValue("dscState", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result{
                
            case .success(let value) :
                let json = JSON(value)
                print(json)
                
                if 0 < json["dscState"].count{
                    self.setData(json)
                } else {
                    CSIndicator.shared.hide()
                    self.showAlert("조회된 내용이 없습니다!", "U")
                }

            case .failure(let error) :
                print("상태관리 상세 조회 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    func setData(_ resJson: JSON){
    
        // 경도
        if resJson["dscState"]["X_GRID"].double != nil {
            x_grid = resJson["dscState"]["X_GRID"].double!
        }
        
        // 위도
        if resJson["dscState"]["Y_GRID"].double != nil {
            y_grid = resJson["dscState"]["Y_GRID"].double!
        }
        
        // 기기명
        lblDeviceNm.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["ATM_NM"].string)
        
        // 기기번호
        lblDeviceNo.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["ORG_CD"].string)
        
        // 기기등급
        let imageGrade = ("icon_grade_" + resJson["dscState"]["ATM_GRADE"].string! + ".png")
        
        imgGrade.image = UIImage(named: imageGrade)
        
        
        // 발생시간
        lblDownTime.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["DOWN_TIME"].string)
        
        // 기기상태
        lblDownStatus.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["DOWN_ATM_NM"].string)

        // 지사
        lblJisa.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["BRANCH_GB_NM"].string)
        
        // 기기위치
        txtLocation.text = FunctionClass.shared.isNullOrBlankReturn(resJson["dscState"]["ADDR_RMK"].string)
        
        txtLocation.isEditable = false
        
        // 장애/긴급출동 건수
        lblIssueDS.text = "장애 " + String(describing: resJson["dscState"]["FAILURE_COUNT"].int!) + "건, 긴급 " + String(describing: resJson["dscState"]["URGENT_COUNT"].int!) + "건"
        
        lblImage01.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_01"].string) ? "등록" : "미등록")
        lblImage02.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_02"].string) ? "등록" : "미등록")
        lblImage03.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_03"].string) ? "등록" : "미등록")
        lblImage04.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_04"].string) ? "등록" : "미등록")
        lblImage05.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_05"].string) ? "등록" : "미등록")
        lblImage06.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_06"].string) ? "등록" : "미등록")
        lblImage07.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_07"].string) ? "등록" : "미등록")
        lblImage08.text = (!FunctionClass.shared.isNullOrBlank(resJson["dscState"]["IMG_REG_DATE_08"].string) ? "등록" : "미등록")
        
        createPicker(tfStatus)
        
        CSIndicator.shared.hide()
    }
    
    // 특이 사항 등록 함수
    func inputData(){
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")       // 기기번호
        http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")    // 지사구분
        http.paramData.setValue(selectedSt, forKey: "check_case")   // 특이사항 케이스
        http.paramData.setValue(repair_memo, forKey: "repair_memo")  // 특이사항 내용
        http.paramData.setValue("", forKey: "photo_nm")     // 사진명
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "repair_reg_nm")// 작성자 아이디
        
        http.paramBox.setValue("saveIssue", forKey: "method")
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
                print("상태등록 실패 >> \(error.localizedDescription)")
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    // 특이사항 등록 결과 정리 함수
    func setInputData(_ resJson: JSON){
        
        CSIndicator.shared.hide()
        
        print("등록할 이미지 갯수 >> \(imgCnt)")
        
        // 등록 성공 확인
        if resJson["saveIssue"]["code"].int! == 0 {
            
            // 업로드할 이미지가 있을 경우 업로드 함수 실행
            if 0 < imgCnt {
                print("이미지 등록 시작")
                uploadImage()
            }else {
                print("이미지 등록 안함")
                self.showAlert("특이사항 내용이 등록되었습니다.", "U")
            }
        } else {
            self.showAlert("등록에 실패했습니다.", "N")
        }
    }
    
    // 이미지 업로드 함수
    func uploadImage(){
        
        CSIndicator.shared.show(view)
    
        let http = HttpRequest(option: "image")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")       // 기기번호
        http.paramData.setValue("STATE", forKey: "type")    // 지사구분
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "img_reg_user")// 작성자 아이디
        
        var paramImg : NSMutableDictionary
        
        for i in 1...IMG_CNT{

            if imageMap[i] != nil {
                
                paramImg = NSMutableDictionary()
                
                paramImg.setValue(imageMap[i]!.data1, forKey: "original")   // 원본이미지
                paramImg.setValue(imageMap[i]!.data2, forKey: "thumb")      // 원본이미지
                paramImg.setValue(imageMap[i]!.data3, forKey: "img_type")   // 이미지 타입(이미지 이름)
                
                http.paramArray.add(paramImg)
            }
        }

        http.paramData.setValue(http.paramArray, forKey: "file")
        
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
    
    // 이미지 업로드 결과 정리 함수
    func setUploadImage(_ resJson: JSON){
        
        // 등록 성공 확인
        if resJson["code"].string! == "0" {
            self.showAlert("특이사항 내용이 등록되었습니다.", "U")
        } else {
            self.showAlert("등록에 실패했습니다.", "N")

        }
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
    
    func createPicker(_ textField : UITextField){
        
        let pv = UIPickerView()
        
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
            
            tfStatus.text = statusArr[selectedSt]
            
            // 선택일 경우 특이사항 초기화
            if selectedSt == 0 {
                txtMemo.text = nil
            }else {
                txtMemo.text = statusArr[selectedSt]
            }

        }
        
        self.view.endEditing(true)
        
    }
    
    // 카메라
    @IBAction func btnCameraAction(_ sender: UIButton) {
        
        switch sender.tag {
            
        case btnImage01.tag:
            
            print("여기타냐 1")
            currentImage = 1
            
            if imageMap[1] != nil {
                print("이미지 삭제")
                imageMap[1] = nil
                imgDevice01.image = nil
                imgCnt = imgCnt - 1
                
                btnImage01.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
            
        case btnImage02.tag:
            print("여기타냐 2")
            currentImage = 2
        
            if imageMap[2] != nil {
                print("이미지 삭제")
                imageMap[2] = nil
                imgDevice02.image = nil
                imgCnt = imgCnt - 1
                btnImage02.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }

        case btnImage03.tag:
            print("여기타냐 3")
            currentImage = 3
            
            if imageMap[3] != nil {
                print("이미지 삭제")
                imageMap[3] = nil
                imgDevice03.image = nil
                imgCnt = imgCnt - 1
                btnImage03.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }

        case btnImage04.tag:
            print("여기타냐 4")
            currentImage = 4
            
            if imageMap[4] != nil {
                print("이미지 삭제")
                imageMap[4] = nil
                imgDevice04.image = nil
                imgCnt = imgCnt - 1
                btnImage04.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
            
        case btnImage05.tag:
            print("여기타냐 5")
            currentImage = 5
            
            if imageMap[5] != nil {
                print("이미지 삭제")
                imageMap[5] = nil
                imgDevice05.image = nil
                imgCnt = imgCnt - 1
                btnImage05.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
            
        case btnImage06.tag:
            print("여기타냐 6")
            currentImage = 6
            
            if imageMap[6] != nil {
                print("이미지 삭제")
                imageMap[6] = nil
                imgDevice06.image = nil
                imgCnt = imgCnt - 1
                btnImage06.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
            
        case btnImage07.tag:
            print("여기타냐 7")
            currentImage = 7
            
            if imageMap[7] != nil {
                print("이미지 삭제")
                imageMap[7] = nil
                imgDevice07.image = nil
                imgCnt = imgCnt - 1
                btnImage07.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
            
        case btnImage08.tag:
            print("여기타냐 8")
            currentImage = 8
            
            if imageMap[8] != nil {
                print("이미지 삭제")
                imageMap[8] = nil
                imgDevice08.image = nil
                imgCnt = imgCnt - 1
                btnImage08.setTitle("사진첨부", for: .normal)
            } else {
                showAlert()
            }
        
        default:
            break
        }
    }
    
    // 저장
    @IBAction func btnSave(_ sender: UIButton) {
        
        if selectedSt == 0 {
            self.showAlert("점검유형을 선택하여 주세요.", "N")
        } else {
        
            repair_memo = txtMemo.text.trimmingCharacters(in: .whitespaces)
            if repair_memo != ""{
                inputData()
            } else {
                self.showAlert("특이사항을 입력하여 주세요.", "N")
            }
        }
    }
    
    // 취소
    @IBAction func btnCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
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
    
    
    
    // 시재정보
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
    
    
    func showAlert(){
    
        let alert = UIAlertController(title: "선택", message: "사진 가져오기", preferredStyle: .actionSheet)
        
        
        alert.addAction(UIAlertAction(title: "카메라", style: .default, handler: { (action) in
             self.useCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "카메라롤", style: .default, handler: { (action) in
            self.useCameraRoll()
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func useCamera(){
        
        newMedia = true
    
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true, completion: nil)
    
    }
    
    func useCameraRoll(){
        
        newMedia = false
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /* PickerView Delegate & DataSource */
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return statusArr.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedSt = row
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return statusArr[row]
    }
    /* PickerView Delegate & DataSource */
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        
        // 이미지
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // 원본이미지 NSData
        let imageData: NSData = UIImageJPEGRepresentation(image, 0.4)! as NSData
        
        // 썸네일 NSData
        let imageThumbData: NSData = UIImageJPEGRepresentation(FunctionClass.shared.thumbnailImage(image), 0.4)! as NSData
        let thumbImage = FunctionClass.shared.thumbnailImage(image)
        
        imageVO = BasicVO()
        
        switch currentImage {
            
        case 1:
            btnImage01.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "01"
            
            imgDevice01.image = thumbImage
            
            imageMap[1] = imageVO
            
        case 2:
            
            btnImage02.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "02"
            
            imgDevice02.image = thumbImage
            
            imageMap[2] = imageVO
            
        case 3:
            
            btnImage03.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "03"
            
            imgDevice03.image = thumbImage
            
            imageMap[3] = imageVO
            
        case 4:
            
            btnImage04.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "04"
            
            imgDevice04.image = thumbImage
            
            imageMap[4] = imageVO
            
        case 5:
            
            btnImage05.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "05"
            
            imgDevice05.image = thumbImage
            
            imageMap[5] = imageVO
            
        case 6:
            
            btnImage06.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "06"
            
            imgDevice06.image = thumbImage
            
            imageMap[6] = imageVO
            
        case 7:
            
            btnImage07.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "07"
            
            imgDevice07.image = thumbImage
            
            imageMap[7] = imageVO
            
        case 8:
            
            btnImage08.setTitle("삭제", for: .normal)
            
            imageVO.data1 = imageData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data2 = imageThumbData.base64EncodedString(options: .init(rawValue: 0))
            
            imageVO.data3 = "08"
            
            imgDevice08.image = thumbImage
            
            imageMap[8] = imageVO
            
        default:
            break
        }
        
        print("변형한 이미지 순서 >> \(imageVO.data3)")
//        print("원본 이미지 Base64 >> \(imageVO.data1)")
//        print("썸네일 이미지 Base64 >> \(imageVO.data2)")
        
        imageList.append(imageVO)
        
        imgCnt = imgCnt + 1
        
        print("이미지 갯수 >> \(imgCnt)")
        
        if newMedia {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }

    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // 긴급출동
        if segue.identifier == "Urgent" {               // 긴급출동
            
            let destination = segue.destination as! IssueViewController
            
            destination.downGB = "U"
            
        } else if segue.identifier == "Issue"{          // 장애관리
            
            let destination = segue.destination as! IssueViewController
            
            destination.downGB = "I"
        
        } else if segue.identifier == "segAtmInfo" {    // 기기정보
            
            let destination = segue.destination as! AtmInfoController
            destination.org_cd = org_cd
            
        } else if segue.identifier == "segIssueHIS"{    // 장애이력
            
            let destination = segue.destination as! IssueHISViewController
            destination.org_cd = org_cd
            
        } else if segue.identifier == "segGoods"{       // 시재정보
            
            let destination = segue.destination as! GoodsInfoViewController
            destination.org_cd = org_cd
            

        }else if segue.identifier == "segLocationMap"{   // 지도보기
            
            let destination = segue.destination as! GoogleMapViewController
            destination.xGrid = x_grid
            destination.yGrid = y_grid
            destination.viewName = "POINT"
            destination.org_cd = org_cd
            destination.deviceName = lblDeviceNm.text!
            
        } else if segue.identifier == "segRouteMap"{     // 경로보기
            
            let destination = segue.destination as! GoogleMapViewController
            destination.xGrid = x_grid
            destination.yGrid = y_grid
            destination.viewName = "ROUTE"
            destination.deviceName = lblDeviceNm.text!
            
        }
    }
}
