//
//  GoogleMapViewController.swift
//  AMS
//
//  Created by 정재호 on 2017. 6. 1..
//  Copyright © 2017년 hirosi. All rights reserved.
//

import UIKit
import GLKit
import Alamofire
import SwiftyJSON
import GoogleMaps

class GoogleMapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, SearchViewControllerDelegate {
    
    @IBOutlet weak var googleMaps: GMSMapView!

    let locationManager = CLLocationManager()
    
    var locationStart = CLLocation()
    var locationEnd = CLLocation()
    var northEast = CLLocation()
    var southWest = CLLocation()
    
    var zoomLevel: Float = 15.0
    open var xGrid = 0.0
    open var yGrid = 0.0
    open var viewName = ""
    open var deviceName = ""
    open var org_cd = ""
    
    var searchFlag: Bool = true

    var pointMarker: GMSMarker!

    override func viewDidLoad() {
        super.viewDidLoad()

        googleMaps.delegate = self
        googleMaps.settings.compassButton = true
        googleMaps.settings.zoomGestures = true
        
        print("넘어온 좌표값 >> \(yGrid) \(xGrid)")

        if viewName == "POINT" {
            
            self.navigationItem.title = "지도보기"

            self.navigationItem.setRightBarButton(UIBarButtonItem(title: "위치조회",
                                                                  style: .plain,
                                                                  target: self,
                                                                  action: #selector(searchLocation)),
                                                  animated: true)
            
            let camera = GMSCameraPosition.camera(withLatitude: yGrid, longitude: xGrid, zoom: zoomLevel)
            
            pointMarker = GMSMarker()
            pointMarker.position = CLLocationCoordinate2DMake(yGrid, xGrid)
            pointMarker.title = deviceName
            pointMarker.isDraggable = true
            pointMarker.map = googleMaps
            googleMaps.selectedMarker = pointMarker
            googleMaps.camera = camera
        
        } else if viewName == "ROUTE" {
            
            self.navigationItem.title = "경로보기"
            
            // 내위치 셋팅, 내위치 버튼 활성화
            googleMaps.isMyLocationEnabled = true
            googleMaps.settings.myLocationButton = true
            
            // Location Manager 셋팅
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 50
        
            // 도착지 정보 셋팅
            locationEnd = CLLocation(latitude: yGrid, longitude: xGrid)
        } else {
            
            self.navigationItem.title = "주변기기"
            
            // 내위치 셋팅, 내위치 버튼 활성화
            googleMaps.isMyLocationEnabled = true
            googleMaps.settings.myLocationButton = true
            
            // Location Manager 셋팅
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 50
        
        }

    }
    
    func searchLocation() {
        self.performSegue(withIdentifier: "seqSearchLocation", sender: nil)
    }
    
    func searchViewControllerResponse(x: Double, y: Double, org_cd: String, device_nm: String) {
        
        self.xGrid = x
        self.yGrid = y
        self.viewName = "POINT"
        self.org_cd = org_cd
        self.deviceName = device_nm
        
        pointMarker.position = CLLocationCoordinate2DMake(yGrid, xGrid)
        pointMarker.title = deviceName
        googleMaps.camera = GMSCameraPosition.camera(withTarget: CLLocationCoordinate2DMake(yGrid, xGrid), zoom: zoomLevel)
    }

    // 반경이동 함수
    func move(statLocation: CLLocation, toNorth: Double, toEarth: Double) -> CLLocation {

        let lonDiff = meterToLongitude(meterToEast: toEarth, latitude: statLocation.coordinate.latitude)
        let latDiff = meterToLatitude(meterToNorth: toNorth)

        return CLLocation(latitude: (statLocation.coordinate.latitude + latDiff),
                          longitude: (statLocation.coordinate.longitude + lonDiff))
    
    }
    // 특정거리 경도 구하기
    func meterToLongitude(meterToEast: Double, latitude: Double) -> Double {
        
        let latArc = degreeToRadians(degree: latitude)
        let radius = cos(latArc) * kGMSEarthRadius
        let rad = meterToEast / radius
        return radiansToDegree(radians: rad)
    }
    
    // 특정거리 위도 구하기
    func meterToLatitude(meterToNorth: Double) -> Double {
        
        let rad = meterToNorth / kGMSEarthRadius
        return radiansToDegree(radians: rad)
    }
    
    func degreeToRadians(degree: Double) -> Double{
        
        return degree * Double.pi / 180.0
    }
    
    func radiansToDegree(radians: Double) -> Double {
    
        return radians * 180.0 / Double.pi
    }
    
    func createCustomMarker(titleMarker: String, lat: CLLocationDegrees, lng: CLLocationDegrees){
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(lat, lng)
    
        let DynamicView = UIView(frame: CGRect(origin: CGPoint(x:0, y:0), size: CGSize(width: 200, height: 100)))
        
        DynamicView.backgroundColor = UIColor.clear
        
        var imgPinMarker: UIImageView
        
        imgPinMarker = UIImageView(frame: CGRect(origin: CGPoint(x:80, y:45), size: CGSize(width: 25, height: 25)))
        imgPinMarker.image = UIImage(named: "ic_pin_01.png")
        
        let text = UILabel(frame: CGRect(origin: CGPoint(x:0, y:0), size: CGSize(width: 200, height: 45)))
        text.backgroundColor = UIColor.white
        text.text = titleMarker
        
        text.numberOfLines = 3
        text.adjustsFontSizeToFitWidth = true
        text.textAlignment = NSTextAlignment.center
        
        DynamicView.addSubview(text)
        DynamicView.addSubview(imgPinMarker)
        
        UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
        DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        marker.icon = imageConverted
        marker.map = self.googleMaps
   
    }
    
    // 마커 생성 함수
    func createMarker(titleMarker: String, lat: CLLocationDegrees, lng: CLLocationDegrees) {
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(lat, lng)
        marker.title = titleMarker
        marker.map = googleMaps
        googleMaps.selectedMarker = marker
    }
    
    // 경로 그리는 함수
    func drawPolyLine(startLocation: CLLocation, endLocation: CLLocation) {

        CSIndicator.shared.show(view)
        
        let start = String(describing: startLocation.coordinate.longitude) + ","
            + String(describing: startLocation.coordinate.latitude)
        
        let end = String(describing: endLocation.coordinate.longitude) + ","
            + String(describing: endLocation.coordinate.latitude)

        
        let url = URL(string: "http://map.naver.com/findroute2/findCarRoute.nhn?via=&call=route2&output=json&car=0&mileage=12.4&start=" + start + "&destination=" + end + "&search=2")!
        
//        let urlSession = URLSession.shared
//        
//        let getRequest = URLRequest(url: url)
//        
//        let task = urlSession.dataTask(with: getRequest) { (data, response, error) in
//            
//            guard error == nil else {
//                return
//            }
//            
//            guard let data = data else {
//                return
//            }
//            
//            do {
//                
//                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]{
//                
//                    print(json)
//                }
//            } catch let error {
//                print(error.localizedDescription)
//            }
//        }
//        
//        task.resume()
        
        // 
        
        Alamofire.request(url).responseJSON { (response) in
            
            switch response.result {
            
            case .success(let value):
                let json = JSON(value)
                let jsonRoute = json["route"].arrayValue
                var jsonPoint:[Array<JSON>] = []
                
                for i in 0..<jsonRoute.count{
                    
                    jsonPoint.append(jsonRoute[i]["point"].arrayValue)
                }
                
                print("point >> \(jsonPoint), 갯수 >> \(jsonPoint.count)")
                
                let path = GMSMutablePath()
                
                path.add(CLLocationCoordinate2D(latitude: startLocation.coordinate.latitude,
                                                longitude: startLocation.coordinate.longitude))
                
                for i in 0..<jsonRoute.count{
                
                    for j in 0..<jsonPoint[i].count{
                        
                        if 0 < jsonPoint[i][j]["panorama"].count {
                            print("위도 : \(jsonPoint[i][j]["panorama"]["lat"]), 경도 : \(jsonPoint[i][j]["panorama"]["lng"])")
                            
                            let point = GMSMapPoint(x: jsonPoint[i][j]["panorama"]["lat"].double!, y: jsonPoint[i][j]["panorama"]["lng"].double!)
                            path.add(CLLocationCoordinate2D(latitude: point.x, longitude: point.y))
                        }
                    }
                }
                
                path.add(CLLocationCoordinate2D(latitude: endLocation.coordinate.latitude,
                                                longitude: endLocation.coordinate.longitude))


                
                self.createMarker(titleMarker: "출발", lat: startLocation.coordinate.latitude, lng: startLocation.coordinate.longitude)
                self.createMarker(titleMarker: self.deviceName, lat: endLocation.coordinate.latitude, lng: endLocation.coordinate.longitude)

                // 중간 위치 구하기
                let tempLat = path.coordinate(at: (path.count()/2 + 1)).latitude
                let tempLng = path.coordinate(at: (path.count()/2 + 1)).longitude
                
                // 경로가 35개 이상인 경우 Zoom Level 조절
                if 35 < path.count() {
                    self.googleMaps.camera = GMSCameraPosition.camera(withLatitude: tempLat, longitude: tempLng, zoom: 7)
                } else {
                    self.googleMaps.camera = GMSCameraPosition.camera(withLatitude: tempLat, longitude: tempLng, zoom: 15)
                }

                // 폴리라인 그리기
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = .red
                polyline.strokeWidth = 4.0
                polyline.geodesic = true
                polyline.map = self.googleMaps
                
                CSIndicator.shared.hide()

            case .failure(let error):
                self.showAlert(error.localizedDescription, "N")
                
                CSIndicator.shared.hide()
            }
        }
    }
    
    // 기기 조회
    func getNearAtms() {
 
        searchFlag = false
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_ID"), forKey: "user_id")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GROUP"), forKey: "user_group")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "USER_GRADE"), forKey: "user_grade")
        http.paramData.setValue(UserDefaults.standard.string(forKey: "BRANCH_GB"), forKey: "branch_gb")
        
        http.paramData.setValue(Double(southWest.coordinate.longitude), forKey: "left")
        http.paramData.setValue(Double(northEast.coordinate.longitude), forKey: "right")
        http.paramData.setValue(Double(northEast.coordinate.latitude), forKey: "top")
        http.paramData.setValue(Double(southWest.coordinate.latitude), forKey: "bottom")
        
        http.paramBox.setValue("nearAtms", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        print("조회 파라메터 \(http.paramArray)")
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])

        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                let json = JSON(value)
                
                print(json)
                
                if 0 < json["nearAtms"]["list"].count {
                    self.setNearAtms(json)
                } else {
                    CSIndicator.shared.hide()
                }
                
            case .failure(let error):
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    func setNearAtms(_ resJson: JSON) {
        
        let jsonRoute = resJson["nearAtms"]["list"].arrayValue
        
        for i in 0..<jsonRoute.count{
            
            if !FunctionClass.shared.isNullOrBlank(jsonRoute[i]["ATM_NM"].string){
                
                let title = jsonRoute[i]["ATM_NM"].string! + "\n긴급 : " + String(describing: jsonRoute[i]["URGENT_COUNT"].int!) + "건, " + "장애 : " + String(describing: jsonRoute[i]["FAILURE_COUNT"].int!) + "건"
                createCustomMarker(titleMarker: title,
                                   lat: jsonRoute[i]["Y_GRID"].double!,
                                   lng: jsonRoute[i]["X_GRID"].double!)
            }
        }
        CSIndicator.shared.hide()
    }
    
    // 기기 위치 수정 함수
    func changeLocation() {

        searchFlag = false
        
        CSIndicator.shared.show(view)
        
        let http = HttpRequest(option: "data")
        
        http.paramData.setValue(org_cd, forKey: "org_cd")
        http.paramData.setValue(locationEnd.coordinate.longitude, forKey: "x_grid")
        http.paramData.setValue(locationEnd.coordinate.latitude, forKey: "y_grid")
        
        http.paramBox.setValue("modifyLocation", forKey: "method")
        http.paramBox.setValue(http.paramData, forKey: "params")
        
        http.paramArray.add(http.paramBox)
        
        print("조회 파라메터 \(http.paramArray)")
        
        http.request.httpBody = try! JSONSerialization.data(withJSONObject: http.paramArray, options: [])
        
        Alamofire.request(http.request).responseJSON { (response) in
            
            switch response.result {
                
            case .success(let value):
                let json = JSON(value)
                
                print(json)
                
                CSIndicator.shared.hide()
                
                if 0 == json["modifyLocation"]["code"].int! {
                    self.showAlert("기기위치 수정을 성공하였습니다!",  "N")
                } else {
                    self.showAlert("기기위치 수정을 실패했습니다!", "N")
                }

                
            case .failure(let error):
                self.showAlert(error.localizedDescription, "N")
                CSIndicator.shared.hide()
            }
        }
    }
    
    // 알림 함수
    func showAlert(_ msg: String, _ kind : String){
        
        let toast = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        
        
        if kind == "U" {
            let okAction = UIAlertAction(title: "확인", style: .default) { (UIAlertAction) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    toast.dismiss(animated: true, completion: nil)
                    self.changeLocation()
                }
            }
            
            let cancelAction = UIAlertAction(title: "취소", style: .default, handler: { (UIAlertAction) in
                self.pointMarker.position = CLLocationCoordinate2DMake(self.yGrid, self.xGrid)
            })
            
            toast.addAction(okAction)
            toast.addAction(cancelAction)
            
        } else if kind == "N"{
            let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
            toast.addAction(okAction)
        }
        
        self.present(toast, animated: true, completion: nil)
    }
    
    // 현재 위치
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationStart = locations.last!

        // 현재 위치로 카메라 이동
        googleMaps.camera = GMSCameraPosition.camera(withLatitude: locationStart.coordinate.latitude,
                                                     longitude: locationStart.coordinate.longitude, zoom: zoomLevel)
        
        
        if viewName == "ROUTE" {
            
            drawPolyLine(startLocation: locationStart, endLocation: locationEnd)
            
        } else {
            northEast = self.move(statLocation: locationStart, toNorth: 500.0, toEarth: 500.0)
            southWest = self.move(statLocation: locationStart, toNorth: -500.0, toEarth: -500.0)
            
            print("현재 위치 >>> \(locationStart.coordinate.latitude) \(locationStart.coordinate.longitude)")
            print("northEast >>> \(northEast.coordinate.latitude) \(northEast.coordinate.longitude)")
            print("southWest >>> \(southWest.coordinate.latitude) \(southWest.coordinate.longitude)")
            
            
            if searchFlag {
                createMarker(titleMarker: "현재위치",
                             lat: locationStart.coordinate.latitude,
                             lng: locationStart.coordinate.longitude)
                getNearAtms()
            }
        }
        
        // 현재 위치 업데이트 중지
        self.locationManager.stopUpdatingLocation()

    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("최종 좌표 >> \(marker.position.latitude) \(marker.position.longitude)")
        
        self.showAlert("기기 위치를 수정하시겠습니까?", "U")
        locationEnd = CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        googleMaps.isMyLocationEnabled = true
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        googleMaps.isMyLocationEnabled = true
        
        if gesture {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        googleMaps.isMyLocationEnabled = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("COORDINATE >>> \(coordinate)")
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {

        googleMaps.isMyLocationEnabled = true
        googleMaps.selectedMarker = nil
        
        searchFlag = true
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "seqSearchLocation" {
            
            let destination = segue.destination as! SearchLocationViewController
            
            destination.delegate = self
            destination.org_cd = org_cd
        }
    }
}
