//
//  InterfaceController.swift
//  MC3 Collecting AcceGyro Data WatchKit Extension
//
//  Created by Eki Rifaldi on 19/07/20.
//  Copyright © 2020 Eki Rifaldi. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var labelInfo: WKInterfaceLabel!
    
    var wcSession : WCSession!
    var motion = CMMotionManager()
    var dataMotionArray:[Dictionary<String, AnyObject>] =  Array()
    var locationManager = CLLocationManager()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        print("awake")
        
        // Configure interface objects here.
        
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print("willActivate")
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        
//        locationManager.allowsBackgroundLocationUpdates = true
        
//        print(motion.isDeviceMotionAvailable ? "Motion available" : "Motion NOT available")
//        print(motion.isGyroAvailable ? "Gyro available" : "Gyro NOT available")
//        print(motion.isAccelerometerAvailable ? "Accel available" : "Accel NOT available")
//        print(motion.isMagnetometerAvailable ? "Mag available" : "Mag NOT available")
    }
    
    override func didDeactivate() {
        print("didDeactivate")
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
}

//    MARK: - WCSession
extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        let instruction = message["messageFromIos"] as! String
        
        print(instruction)
        
        switch instruction {
        case "START":
            labelInfo.setText("Recording data...")
            dataMotionArray.removeAll()
            startDeviceMotion()
            break
        case "STOP":
            labelInfo.setText("Stopping...")
            stopUpdates()
            print("SIZE: \(dataMotionArray.count)")
            let csvStr = generateCsvFormat(motionArray: dataMotionArray)
            sendMessage(strMsg: csvStr)
            dataMotionArray.removeAll()
            break
        default:
            labelInfo.setText("Instruksi naon iyee...")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // Code.
        
    }
}

//MARK: - CoreMotion
extension InterfaceController {
    
    func startDeviceMotion(){
        print("Start DeviceMotion")
        motion.deviceMotionUpdateInterval  = 1.0 / 50.0
        motion.startDeviceMotionUpdates(to: OperationQueue.current!) {
            (data, error) in
//            print("Motion")
            print(data as Any)
            if let trueData =  data {
                
                var dct = Dictionary<String, AnyObject>()
                dct.updateValue(self.getNowTime() as AnyObject, forKey: "Time")
                dct.updateValue(trueData.userAcceleration.x as AnyObject, forKey: "AcceX")
                dct.updateValue(trueData.userAcceleration.y as AnyObject, forKey: "AcceY")
                dct.updateValue(trueData.userAcceleration.z as AnyObject, forKey: "AcceZ")
                dct.updateValue(trueData.rotationRate.x as AnyObject, forKey: "GyroX")
                dct.updateValue(trueData.rotationRate.y as AnyObject, forKey: "GyroY")
                dct.updateValue(trueData.rotationRate.z as AnyObject, forKey: "GyroZ")
                self.dataMotionArray.append(dct)
                
            }
        }
        return
    }
    
    func stopUpdates() {
        if motion.isDeviceMotionAvailable {
//            motion.stopGyroUpdates()
            motion.stopDeviceMotionUpdates()
//            motion.stopAccelerometerUpdates()
        }
    }
    
    func generateCsvFormat(motionArray:[Dictionary<String, AnyObject>]) -> String {
        var csvString = "\("Time"),\("Accelerometer X"),\("Accelerometer Y"),\("Accelerometer Z"),\("Gyroscope X"),\("Gyroscope Y"),\("Gyroscope Z")\n"
        for dct in motionArray {
            csvString = csvString.appending("\(String(describing: dct["Time"]!)),\(String(describing: dct["AcceX"]!)),\(String(describing: dct["AcceY"]!)),\(String(describing: dct["AcceZ"]!)),\(String(describing: dct["GyroX"]!)),\(String(describing: dct["GyroY"]!)),\(String(describing: dct["GyroZ"]!))\n")
        }
        
        return csvString
    }
    
    func sendMessage(strMsg: String){
        let message = ["messageFromWatch":strMsg]
        wcSession.sendMessage(message, replyHandler: nil) { (error) in
            
            print(error.localizedDescription)
            
        }
        print("Sent")
        labelInfo.setText("Waiting...")
    }
    
    func getNowTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        let strDate = "\(hour):\(minutes):\(seconds).\(nanoseconds)"
        return strDate
    }
}
