//
//  ViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 4. 24..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate, XMLParserDelegate {

    @IBOutlet weak var tfID: UITextField!
    
    @IBOutlet weak var tfPassWord: UITextField!
    
    @IBOutlet weak var btnCheck: UIButton!
    
    @IBOutlet weak var btnLogin: UIButton!
    
    var token : String = ""
    var device_id : String = ""
    
    var isBoxChecked:Bool!

    var version: String?
    var newVersion: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Build Number >> \(String(describing: Bundle.main.buildNumber))")

        

        // FCM token 획득
        if FIRInstanceID.instanceID().token() != nil {
            token = FIRInstanceID.instanceID().token()!
        }

        device_id = UIDevice.current.identifierForVendor!.uuidString
        print("token \(token)")
        print("Device ID >> \(device_id)")
        
        tfID.delegate = self
        tfPassWord.delegate = self
        
        if UserDefaults.standard.object(forKey: "REMEMBER_ID") != nil{
            
            tfID.text = UserDefaults.standard.string(forKey: "REMEMBER_ID")
            btnCheck.setImage(UIImage(named: "checked.png"), for: .normal)
            isBoxChecked = true
            
        }else{
            isBoxChecked = false
            tfID.text = ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // 버전체크
        versionCheck()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tfID.resignFirstResponder()
        tfPassWord.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == tfID {
            tfPassWord.becomeFirstResponder()
        }else{
            
            tfPassWord.resignFirstResponder()
            loginAction(btnLogin)

        }

        return true
    }


    @IBAction func idSaveAction(_ sender: UIButton) {

        print(isBoxChecked)
        
        if isBoxChecked {
            isBoxChecked = false
        } else {
            isBoxChecked = true
        }
        print(isBoxChecked)
            
        if isBoxChecked {
            btnCheck.setImage(UIImage(named: "checked.png"), for: .normal)
        } else {
            btnCheck.setImage(UIImage(named: "unchecked.png"), for: .normal)
        }
        print(isBoxChecked)
  
    }

    @IBAction func loginAction(_ sender: UIButton) {
        
        let userId: String = (tfID.text?.trimmingCharacters(in: .whitespaces))!
        let userPass: String = (tfPassWord.text?.trimmingCharacters(in: .whitespaces))!
        
        print("\(userId)\(userPass)")
        
        if userId != "" && userPass != ""{
            // 키보드 내리기
            tfPassWord.resignFirstResponder()
            loginUser()
        } else {
            self.showToast("로그인 정보를 입력하세요!", "N")
        }
    }
    
    func versionCheck(){
        
        // 테스트용 : 내용 바꿀예정
        let url: String = "http://210.105.193.181:10004/BGFMams/version_ios.xml"
        let urlToSend : URL = URL(string: url)!
        let parser = XMLParser(contentsOf: urlToSend)
        parser?.delegate = self
        parser?.parse()
        
        print("xml 파싱>> \(newVersion!)")
        

        
        if Int(Bundle.main.buildNumber!)! < Int(newVersion!)! {
            
            let url: String = "http://210.105.193.181:10004/BGFMams/ams.html"
            let urlToSend : URL = URL(string: url)!
            
            let alertUpdate = UIAlertController(title: "앱 업데이트",
                                                message: "새로운 버전이 출시되어 설치할 준비가 되었습니다.",
                                                preferredStyle: .alert)
            
            let actionInstall = UIAlertAction(title: "바로 설치하기", style: .default, handler: { (UIAlertAction) in
                
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(urlToSend, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(urlToSend)
                }
                
            })
            
            let actionLater = UIAlertAction(title: "나중에", style: .cancel, handler: nil)
            
            alertUpdate.addAction(actionInstall)
            alertUpdate.addAction(actionLater)
            
            self.present(alertUpdate, animated: true, completion: nil)
            
        } else {
            print("최신버전")
        }
    }
    
    func loginUser() {
        
        CSIndicator.shared.show(view)
        
        // FCM token 획득
        if FIRInstanceID.instanceID().token() != nil {
            token = FIRInstanceID.instanceID().token()!
        }
        
        // 데이터 전송 http 인스턴스 생성
        // option : "data" >> CRUD 데이터 전송 URL 셋팅
        // option : "" OR "image" >> 이미지 전송 URL 셋팅
        let http = HttpRequest(option: "data")
        
        // 아이디
        http.paramData.setValue(tfID.text!, forKey: "user_id")
        //        http.paramData.setValue("hirosi", forKey: "user_id")
        //        http.paramData.setValue("20030402", forKey: "user_id")    // 지사장 SM
        //        http.paramData.setValue("20120605", forKey: "user_id")    // CM
        
        // 패스워드
        http.paramData.setValue(tfPassWord.text!, forKey: "user_passwd")
        //        http.paramData.setValue("Amkor123!", forKey: "user_passwd")
        //        http.paramData.setValue("bgf#24680!", forKey: "user_passwd")
        //        http.paramData.setValue("bgf12345!", forKey: "user_passwd")
        
        // 기기 아이디
        http.paramData.setValue(device_id, forKey: "device_id")
        
        // 기기 구분값
        http.paramData.setValue("91", forKey: "device_type")
        
        // fcm 토근
        http.paramData.setValue(token, forKey: "app_reg_id")
        
        // 공지상태값 항상 "N"
        http.paramData.setValue("N", forKey: "noti_expire_yn")
        
        // API 호출 메소드명
        http.paramBox.setValue("login", forKey: "method")
        
        // API 매개변수
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        // 최종 Array 형태로 래핑
        http.paramArray.add(http.paramBox)
        
        
        // 전송 데이터 JSON으로 변환
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        // API requet
        Alamofire.request(http.request).responseJSON { (response) in
            print(response.result)
            
            switch response.result {
                
            case .success(let value) :
                let json = JSON(value)
                self.saveUserData(json)
                print("로그인 성공 >> \(json)")
                
            case .failure(let error) :
                self.showToast(error.localizedDescription, "N")
                print("로그인 실패 \(error.localizedDescription)")
            }
        }
    }
    
    func saveUserData(_ resJson : JSON){
        
        if resJson["login"]["permit"].string! == "Y" {
            
            let appDomain = Bundle.main.bundleIdentifier
            
            UserDefaults.standard.removePersistentDomain(forName: appDomain!)
            
            // 사용자 아이디
            UserDefaults.standard.set(resJson["login"]["USER_ID"].string, forKey: "USER_ID")
            // 사용자명
            UserDefaults.standard.set(resJson["login"]["USER_NM"].string, forKey: "USER_NM")
            // 사용자 그룹
            UserDefaults.standard.set(String(describing:resJson["login"]["USER_GROUP"].int!), forKey: "USER_GROUP")
            // 지사구분
            UserDefaults.standard.set(resJson["login"]["BRANCH_GB"].string, forKey: "BRANCH_GB")
            // 사용자 직책
            UserDefaults.standard.set(String(describing:resJson["login"]["USER_GRADE"].int!), forKey: "USER_GRADE")
            // 업체코드
            UserDefaults.standard.set(resJson["login"]["USER_ENT"].string ==  nil ? "" : resJson["login"]["USER_ENT"].string, forKey: "USER_ENT")
            
            // 사용자 아이디 저장 여부
            if isBoxChecked {
                UserDefaults.standard.set(resJson["login"]["USER_ID"].string, forKey: "REMEMBER_ID")
            } else {
                
                if UserDefaults.standard.object(forKey: "REMEMBER_ID") != nil {
                    UserDefaults.standard.removeObject(forKey: "REMEMBER_ID")
                }
            }
            
            self.showToast("로그인 성공", "Y")
            
        }else{
            self.showToast("로그인 실패 서버 에러", "N")
        }
        

    }
    
    func showToast(_ msg: String, _ kind: String){
        
        CSIndicator.shared.hide()
        
        let toast = UIAlertController(title: "", message: msg, preferredStyle: .alert)

        if kind == "Y" {
            self.present(toast, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                toast.dismiss(animated: true, completion: nil)
                
                self.performSegue(withIdentifier: "segMain", sender: self)
            }
        }else{
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            toast.addAction(okAction)
            self.present(toast, animated: true, completion: nil)
        
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "code" {
            version = String()
        }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "code" {
            newVersion = String()
            newVersion = version
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        let data = string.trimmingCharacters(in: .whitespaces)
        
        
        if !data.isEmpty {

            version = data
        }
    }
}

extension Bundle {
    
    
    var buildNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }

}

