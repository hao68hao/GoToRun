//
//  NewRunViewController.swift
//  GoToRun
//
//  Created by lauda on 17/1/17.
//  Copyright © 2017年 lauda. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation
import MapKit
import CoreData

class NewRunViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //MARK: - 初始化成员变量
    var seconds = 0.0
    var distance = 0.0
    
    var run : Run!
   
    
    //MARK: - 懒生明
    lazy var locationManager : CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = CLActivityType.fitness
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    
    lazy var locationsData = [CLLocation]()
    lazy var timerRun = Timer()

    //MARK: - 关联控件
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    
    //MARK: - 启动跑步按钮
    @IBAction func startRunTap(_ sender: UIButton) {
        seconds = 0.0
        distance = 0.0

        timerRun = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timerls) -> Void in
            self.eachSecond()
        })
        
        locationsData.removeAll(keepingCapacity: false)
        
        startLocationUpdates()
    }
    
    //MARK: - 跑步停止按钮
    @IBAction func stopRunTap(_ sender: UIButton) {
        
        stopLocationUpdates()
//        timerRun.invalidate()
        
        //弹出提示
        let alertVC = UIAlertController(title: "正在记录GPS轨迹", message: "现在停止吗？", preferredStyle: .actionSheet)
        
        let stopAction = UIAlertAction(title: "停止", style: .default) { (action) -> Void in
            self.timerRun.invalidate()
        }
        
        let saveAction = UIAlertAction(title: "停止并保存", style: .default) { (action) -> Void in
            self.saveCoreData()
            
//            self.performSegue(withIdentifier: "showDeatil", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertVC.addAction(stopAction)
        alertVC.addAction(saveAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
        
    }
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //兼容iOS8以下设备
        locationManager.requestAlwaysAuthorization()
        
        mapView.isHidden = true
    }
    
    //MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //退出页面时时间也停止
        timerRun.invalidate()
    }

    //MARK: - didReceiveMemoryWarning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - 每秒更新界面方法
    func eachSecond() {
        seconds += 1
        
        //获取时间数据，更新在时间标签
        let secondsQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: seconds)
        //获取距离数据，更新距离标签
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
        //组合单位，再获取配速数据，更新标签
        let paceUnit = HKUnit.second().unitDivided(by: HKUnit.meter())
        let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: seconds / distance)
        
        timeLabel.text = secondsQuantity.description
        distanceLabel.text = distanceQuantity.description
        paceLabel.text = paceQuantity.description
        
        //组合单位
        //在数学计算中，我们常常会遇到m/s这样的单位。这种单位是由两个单位相除得到的。
        //如果开发者想要在自己的代码中使用这种单位。首先需要使用unitDividedByUnit(_:)方法实现对这种单位的创建
        /*
         let 米 = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
         let 秒 = HKQuantity(unit: HKUnit.second(), doubleValue: seconds)
         let 混合单位 = 米.unitDividedByUnit(秒)
         let 速度 = HKQuantity(unit: 混合单位, doubleValue: 米/秒)
         print("你跑步的速度为：\(速度)")
         */
        
    }
    
    //MARK: - 程序开始更新位置
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
        mapView.isHidden = false
    }
    
    //MARK: - 程序停止更新位置
    func stopLocationUpdates() {
        
        locationManager.stopUpdatingLocation()
        
    }
    
    //MARK: - 实现CLLocationManagerDelegate代理 方法
    /*
     实现位置更新的代理方法，如果小于20米值会自动清除数据，
     如果CLLocation通过了检测，就会开始计算距离。这时候distance(from: CLLocation)方法就很方便了，它能够考虑到各种稀奇古怪的涉及到地球曲面的情况
     1此方法已经获取到了位置信息，并且是每隔一秒更新一次信息，打印locations即可看到所有的位置信息
     2声明一个新的变量，将位置信息传给它，并对它进行遍历
     3在遍历过程中，首先对位置的水平信息进行判断，如果小于20米，则忽略不计（标准是小于0则不计算）；
     4计算距离，在计算距离前判断位置信息点数是否大于0，如果大于0可以计算累计的距离。
     5最后将位置数据添加到新的变量中。
     
     1、实现CLLocationManagerDelegate代理的locationManager(_:didUpdateLocations:)方法，获取到位置相关的数据保存到locations数组中。
     2、实例化locations数组为xiaoLocation，并对它进行遍历。
     3、先判断获取到的位置数据中的水平数据horizontalAccuracy，如果小于20米，则忽略不计
     4、在此基础上再进行全局变量locationsData的数组判断，如果数据为空，则进行距离计算
     5、最后将实例化的xiaoLocation数据添加到locationsData数组
     
    */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        for xiaoLocation in locations {
            
            let howRecnt = xiaoLocation.timestamp.timeIntervalSinceNow
            
            if abs(howRecnt) < 10 && xiaoLocation.horizontalAccuracy < 20 {
                if locationsData.count > 0 {
                    distance += xiaoLocation.distance(from: self.locationsData.last!)
                    
                    // 实时更新地图的位置并显示在地图
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locationsData.last!.coordinate)
                    coords.append(xiaoLocation.coordinate)
                    
                    let region = MKCoordinateRegionMakeWithDistance(xiaoLocation.coordinate, 500, 500)
                    mapView.setRegion(region, animated: true)
                    
                    mapView.add(MKPolyline(coordinates: &coords, count: coords.count))
                }
            }
            self.locationsData.append(xiaoLocation)
            
            print("-=----==========\(locationsData)")
            
            
        }
    }
    
    //MARK: - MKMapViewDelegate的overlay渲染声明
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        var resultRender = MKOverlayRenderer()
        
        if overlay.isKind(of: MKPolyline.self) {
            let render: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            render.lineWidth = 3
            render.strokeColor = UIColor.red
            resultRender = render
            
        } else if overlay.isKind(of: MKCircle.self) {
            let circleRender: MKCircleRenderer = MKCircleRenderer(overlay: overlay)
            circleRender.fillColor = UIColor.cyan
            circleRender.alpha = 0.1
            resultRender = circleRender
        }
        return resultRender
    }
    
    //MARK: - coredata存储数据
    func saveCoreData() {
        
        //一、初始化
        //1、实例化总代理
        //2、获取代理中的缓冲区，并实例化。
        //3、实例缓冲区的对象saveRun，描述需要插入到缓冲区对象的数据模型实体（entity-Run）,强制转换为Run
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managerObjectContext = appDelegate.managedObjectContext
        let saveRun = NSEntityDescription.insertNewObject(forEntityName: "Run", into: managerObjectContext) as! Run
        
        //二、实体与数据模型一一对应
        
        //1、将GPS数据赋值给缓冲区实例化的对象saveRun，对应数据模型的Run实体，向Run实体的四个属性duration，distance，timestamp，locations赋值，前三个直接赋值；
        //2、第四个属性locations关联的是另一个实体Location，所以在插入locations数据时，进入数据描述和遍历；
        //2.1、插入locations的数据来源于：locationManager(_:didUpdateLocations:)方法获取到的系统GPS数据，这些数据保存到locationsData实例中（全局实例，类型是CLLocation）；
        //2.2、先声明一个临时的实例xiaoLocation，类型是Location模型；
        //2.3、对locationsData实例遍历；
        //2.4、遍历第一步：声明实例缓冲区的对象saveLocations，描述需要插入到缓冲区对象的数据模型实体（entity-Location）,强制转换为Location类型；
        //2.5、一一插入数据到saveLocations对象的属性中，数据取自coordinate；
        //2.6、遍历后的数据添加到临时的实例xiaoLocation；
        //3、向第四个属性saveRun.locations赋值； 
        //4、将saveRun再赋值给全局实例run，类型是Run模型；
    
        saveRun.duration = seconds as NSNumber
        saveRun.distance = distance as NSNumber
        saveRun.timestamp = NSDate() as Date
        
        //run的模型中有location,因此保存location的数据更复杂一些
        var xiaoLocation = [Location]()
        for neiLocation in locationsData{
            let saveLocations = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managerObjectContext) as! Location
            
            saveLocations.latitude = (neiLocation.coordinate.latitude) as NSNumber
            saveLocations.longitude = (neiLocation.coordinate.longitude) as NSNumber
            saveLocations.timestamp = (neiLocation.timestamp as NSDate) as Date
            xiaoLocation.append(saveLocations)
        }
        saveRun.locations = NSOrderedSet(array: xiaoLocation)
        run = saveRun

        //三、保存数据
        do {
            try managerObjectContext.save()
        }catch{
            print(error)
        }
        
    }

   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
